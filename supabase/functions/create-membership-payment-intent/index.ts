import { createClient } from 'npm:@supabase/supabase-js@2'

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { 'Content-Type': 'application/json' },
  })
}

function stripeFormBody(data: Record<string, string>) {
  return new URLSearchParams(data).toString()
}

async function stripeRequest<T = unknown>({
  path,
  secretKey,
  body,
}: {
  path: string
  secretKey: string
  body: Record<string, string>
}): Promise<T> {
  const res = await fetch(`https://api.stripe.com/v1/${path}`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${secretKey}`,
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: stripeFormBody(body),
  })

  const payload = await res.json()

  if (!res.ok) {
    const message =
      (payload?.error?.message ?? '').toString().trim() ||
      'Stripe request failed'
    throw new Error(message)
  }

  return payload as T
}

type StripeCustomer = {
  id: string
}

type StripePaymentIntent = {
  id: string
  client_secret: string | null
  status: string
}

Deno.serve(async (req) => {
  try {
    if (req.method !== 'POST') {
      return json({ error: 'Method not allowed' }, 405)
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const anonKey = Deno.env.get('SUPABASE_ANON_KEY')!
    const stripeSecretKey = Deno.env.get('STRIPE_SECRET_KEY')!

    if (!stripeSecretKey) {
      return json({ error: 'Missing STRIPE_SECRET_KEY' }, 500)
    }

    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return json({ error: 'Missing Authorization header' }, 401)
    }

    const token = authHeader.replace('Bearer ', '')
    const adminClient = createClient(supabaseUrl, serviceRoleKey)
    const userClient = createClient(supabaseUrl, anonKey, {
      global: {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      },
    })

    const {
      data: { user },
      error: userError,
    } = await userClient.auth.getUser()

    if (userError || !user) {
      return json({ error: 'Unauthorized' }, 401)
    }

    const { data: me, error: meError } = await adminClient
      .from('profiles')
      .select('id, role, gym_id')
      .eq('id', user.id)
      .maybeSingle()

    if (meError || !me || me.role !== 'admin') {
      return json({ error: 'Only admins can create card payments' }, 403)
    }

    const body = await req.json()

    const memberId = (body.memberId ?? '').toString().trim()
    const planId = (body.planId ?? '').toString().trim()
    const notes = (body.notes ?? '').toString().trim()
    const rawAmount = Number(body.amount ?? 0)
    const currency = ((body.currency ?? 'EUR').toString().trim() || 'EUR').toUpperCase()

    if (!memberId) return json({ error: 'memberId is required' }, 400)
    if (!planId) return json({ error: 'planId is required' }, 400)
    if (!Number.isFinite(rawAmount) || rawAmount <= 0) {
      return json({ error: 'amount must be greater than 0' }, 400)
    }

    const gymId = (me.gym_id ?? '').toString().trim()
    if (!gymId) {
      return json({ error: 'Admin gym not found' }, 400)
    }

    const { data: member, error: memberError } = await adminClient
      .from('profiles')
      .select('id, gym_id, full_name, email')
      .eq('id', memberId)
      .eq('gym_id', gymId)
      .maybeSingle()

    if (memberError || !member) {
      return json({ error: 'Member not found for this gym' }, 404)
    }

    const { data: plan, error: planError } = await adminClient
      .from('membership_plans')
      .select('id, gym_id, name, plan_type, billing_period, price, currency')
      .eq('id', planId)
      .eq('gym_id', gymId)
      .maybeSingle()

    if (planError || !plan) {
      return json({ error: 'Plan not found for this gym' }, 404)
    }

    const planType = (plan.plan_type ?? '').toString().trim().toLowerCase()

    const { data: activeMemberships, error: activeMembershipsError } =
      await adminClient
        .from('v_active_member_memberships')
        .select('id, plan_name, name, plan_type, gym_id')
        .eq('member_id', memberId)
        .eq('gym_id', gymId)

    if (activeMembershipsError) {
      return json({ error: activeMembershipsError.message }, 400)
    }

    const hasBlockingConflict =
      (planType === 'unlimited' || planType === 'weekly_limit') &&
      (activeMemberships ?? []).some((membership) => {
        const type = (membership.plan_type ?? '').toString().trim().toLowerCase()
        return type === 'unlimited' || type === 'weekly_limit'
      })

    if (hasBlockingConflict) {
      const blocking = (activeMemberships ?? []).find((membership) => {
        const type = (membership.plan_type ?? '').toString().trim().toLowerCase()
        return type === 'unlimited' || type === 'weekly_limit'
      })

      const blockingName =
        (blocking?.plan_name ?? blocking?.name ?? 'Active membership')
          .toString()
          .trim()

      return json({ error: `Already active: ${blockingName}` }, 409)
    }

    if (planType !== 'class_pack') {
      const now = new Date()
      const dayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate())
      const dayEnd = new Date(dayStart)
      dayEnd.setDate(dayEnd.getDate() + 1)

      const { data: sameDayPaid, error: sameDayPaidError } = await adminClient
        .from('membership_payments')
        .select('id')
        .eq('member_id', memberId)
        .eq('plan_id', planId)
        .eq('payment_status', 'paid')
        .gte('created_at', dayStart.toISOString())
        .lt('created_at', dayEnd.toISOString())
        .limit(1)

      if (sameDayPaidError) {
        return json({ error: sameDayPaidError.message }, 400)
      }

      if ((sameDayPaid ?? []).length > 0) {
        return json(
          { error: 'A payment for this plan is already registered today' },
          409,
        )
      }
    }

    let stripeCustomerId = ''
    const memberEmail = (member.email ?? '').toString().trim()
    const memberName = (member.full_name ?? '').toString().trim()

    const existingStripeCustomerId = ''

    if (existingStripeCustomerId) {
      stripeCustomerId = existingStripeCustomerId
    } else {
      const stripeCustomer = await stripeRequest<StripeCustomer>({
        path: 'customers',
        secretKey: stripeSecretKey,
        body: {
          ...(memberEmail ? { email: memberEmail } : {}),
          ...(memberName ? { name: memberName } : {}),
          'metadata[member_id]': memberId,
          'metadata[gym_id]': gymId,
        },
      })

      stripeCustomerId = stripeCustomer.id
    }

    const amountInCents = Math.round(rawAmount * 100)

    const stripePaymentIntent = await stripeRequest<StripePaymentIntent>({
      path: 'payment_intents',
      secretKey: stripeSecretKey,
      body: {
        amount: String(amountInCents),
        currency: currency.toLowerCase(),
        customer: stripeCustomerId,
        'automatic_payment_methods[enabled]': 'true',
        'metadata[member_id]': memberId,
        'metadata[plan_id]': planId,
        'metadata[gym_id]': gymId,
        'metadata[created_by]': user.id,
      },
    })

    const { data: paymentRow, error: paymentInsertError } = await adminClient
      .from('membership_payments')
      .insert({
        member_id: memberId,
        plan_id: planId,
        amount: rawAmount,
        currency,
        payment_method: 'card',
        payment_status: 'pending',
        created_by: user.id,
        notes: notes || null,
        stripe_customer_id: stripeCustomerId,
        stripe_payment_intent_id: stripePaymentIntent.id,
        metadata: {
          source: 'admin_sell_plan',
          stripe_status: stripePaymentIntent.status,
        },
      })
      .select('id')
      .single()

    if (paymentInsertError || !paymentRow) {
      return json(
        { error: paymentInsertError?.message ?? 'Failed to create payment row' },
        400,
      )
    }

    return json({
      ok: true,
      paymentId: paymentRow.id,
      stripeCustomerId,
      stripePaymentIntentId: stripePaymentIntent.id,
      clientSecret: stripePaymentIntent.client_secret,
    })
  } catch (e) {
    return json(
      { error: e instanceof Error ? e.message : 'Unknown error' },
      500,
    )
  }
})