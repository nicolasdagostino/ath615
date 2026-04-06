import { createClient } from 'npm:@supabase/supabase-js@2'
import Stripe from 'npm:stripe@16.10.0'

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { 'Content-Type': 'application/json' },
  })
}

Deno.serve(async (req) => {
  try {
    if (req.method !== 'POST') {
      return json({ error: 'Method not allowed' }, 405)
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const stripeSecretKey = Deno.env.get('STRIPE_SECRET_KEY')!
    const stripeWebhookSecret = Deno.env.get('STRIPE_WEBHOOK_SECRET')!

    if (!stripeSecretKey) {
      return json({ error: 'Missing STRIPE_SECRET_KEY' }, 500)
    }

    if (!stripeWebhookSecret) {
      return json({ error: 'Missing STRIPE_WEBHOOK_SECRET' }, 500)
    }

    const signature = req.headers.get('stripe-signature')
    if (!signature) {
      return json({ error: 'Missing stripe-signature header' }, 400)
    }

    const rawBody = await req.text()

    const stripe = new Stripe(stripeSecretKey, {
      apiVersion: '2024-06-20',
    })

    let event: Stripe.Event
    try {
      event = await stripe.webhooks.constructEventAsync(
        rawBody,
        signature,
        stripeWebhookSecret,
      )
    } catch (err) {
      const message =
        err instanceof Error ? err.message : 'Invalid webhook signature'
      return json({ error: message }, 400)
    }

    const adminClient = createClient(supabaseUrl, serviceRoleKey)

    if (event.type === 'payment_intent.succeeded') {
      const intent = event.data.object as Stripe.PaymentIntent
      const paymentIntentId = intent.id

      const { data: paymentRow, error: paymentError } = await adminClient
        .from('membership_payments')
        .select(
          'id, member_id, plan_id, membership_id, payment_status, amount, currency, stripe_payment_intent_id',
        )
        .eq('stripe_payment_intent_id', paymentIntentId)
        .maybeSingle()

      if (paymentError) {
        return json({ error: paymentError.message }, 400)
      }

      if (!paymentRow) {
        return json({ ok: true, ignored: 'payment row not found' })
      }

      if (paymentRow.membership_id) {
        await adminClient
          .from('membership_payments')
          .update({
            payment_status: 'paid',
            paid_at: new Date().toISOString(),
            failure_reason: null,
            updated_at: new Date().toISOString(),
            metadata: {
              stripe_status: intent.status,
              webhook_event_type: event.type,
            },
          })
          .eq('id', paymentRow.id)

        return json({ ok: true, alreadyProcessed: true })
      }

      const todayIso = new Date().toISOString().slice(0, 10)

      const { data: membership, error: membershipError } = await adminClient.rpc(
        'assign_membership_plan_internal',
        {
          p_member_id: paymentRow.member_id,
          p_plan_id: paymentRow.plan_id,
          p_status: 'active',
          p_start_date: todayIso,
          p_auto_renew: false,
          p_credits_remaining: null,
          p_classes_used_current_period: 0,
        },
      )

      if (membershipError) {
        await adminClient
          .from('membership_payments')
          .update({
            payment_status: 'failed',
            failure_reason: membershipError.message,
            updated_at: new Date().toISOString(),
            metadata: {
              stripe_status: intent.status,
              webhook_event_type: event.type,
              membership_assign_error: membershipError.message,
            },
          })
          .eq('id', paymentRow.id)

        return json({ error: membershipError.message }, 400)
      }

      const membershipId = (membership?.id ?? '').toString().trim()

      await adminClient
        .from('membership_payments')
        .update({
          membership_id: membershipId || null,
          payment_status: 'paid',
          paid_at: new Date().toISOString(),
          failure_reason: null,
          updated_at: new Date().toISOString(),
          metadata: {
            stripe_status: intent.status,
            webhook_event_type: event.type,
          },
        })
        .eq('id', paymentRow.id)

      return json({ ok: true, paymentId: paymentRow.id, membershipId })
    }

    if (event.type === 'payment_intent.payment_failed') {
      const intent = event.data.object as Stripe.PaymentIntent
      const paymentIntentId = intent.id
      const failureMessage =
        intent.last_payment_error?.message?.toString().trim() ||
        'Stripe payment failed'

      const { data: paymentRow, error: paymentError } = await adminClient
        .from('membership_payments')
        .select('id')
        .eq('stripe_payment_intent_id', paymentIntentId)
        .maybeSingle()

      if (paymentError) {
        return json({ error: paymentError.message }, 400)
      }

      if (!paymentRow) {
        return json({ ok: true, ignored: 'payment row not found' })
      }

      await adminClient
        .from('membership_payments')
        .update({
          payment_status: 'failed',
          failure_reason: failureMessage,
          updated_at: new Date().toISOString(),
          metadata: {
            stripe_status: intent.status,
            webhook_event_type: event.type,
          },
        })
        .eq('id', paymentRow.id)

      return json({ ok: true, paymentId: paymentRow.id, failed: true })
    }

    if (event.type === 'payment_intent.canceled') {
      const intent = event.data.object as Stripe.PaymentIntent
      const paymentIntentId = intent.id

      const { data: paymentRow, error: paymentError } = await adminClient
        .from('membership_payments')
        .select('id')
        .eq('stripe_payment_intent_id', paymentIntentId)
        .maybeSingle()

      if (paymentError) {
        return json({ error: paymentError.message }, 400)
      }

      if (!paymentRow) {
        return json({ ok: true, ignored: 'payment row not found' })
      }

      await adminClient
        .from('membership_payments')
        .update({
          payment_status: 'cancelled',
          updated_at: new Date().toISOString(),
          metadata: {
            stripe_status: intent.status,
            webhook_event_type: event.type,
          },
        })
        .eq('id', paymentRow.id)

      return json({ ok: true, paymentId: paymentRow.id, cancelled: true })
    }

    return json({ ok: true, ignored: event.type })
  } catch (e) {
    return json(
      { error: e instanceof Error ? e.message : 'Unknown error' },
      500,
    )
  }
})