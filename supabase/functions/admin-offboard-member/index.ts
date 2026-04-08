import { createClient } from 'npm:@supabase/supabase-js@2'

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

    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return json({ error: 'Missing Authorization header' }, 401)
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const anonKey = Deno.env.get('SUPABASE_ANON_KEY')!

    const adminClient = createClient(supabaseUrl, serviceRoleKey)

    const token = authHeader.replace('Bearer ', '').trim()
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
      return json({ error: 'Only admins can offboard members' }, 403)
    }

    const adminGymId = (me.gym_id ?? '').toString().trim()
    if (!adminGymId) {
      return json({ error: 'Admin gym not found' }, 400)
    }

    const body = await req.json()
    const memberId = (body.memberId ?? '').toString().trim()
    const reason = (body.reason ?? '').toString().trim()

    if (!memberId) {
      return json({ error: 'memberId is required' }, 400)
    }

    const { data: member, error: memberError } = await adminClient
      .from('profiles')
      .select('id, gym_id, role, is_active')
      .eq('id', memberId)
      .eq('gym_id', adminGymId)
      .maybeSingle()

    if (memberError || !member) {
      return json({ error: 'Member not found' }, 404)
    }

    if (member.role === 'owner') {
      return json({ error: 'Owners cannot be offboarded here' }, 400)
    }

    const today = new Date().toISOString().slice(0, 10)
    const nowIso = new Date().toISOString()

    const { error: profileUpdateError } = await adminClient
      .from('profiles')
      .update({
        is_active: false,
        notes: reason
          ? `${(member as any).notes ?? ''}`.trim()
            ? `${((member as any).notes ?? '').toString().trim()}\n\n[OFFBOARDED ${today}] ${reason}`
            : `[OFFBOARDED ${today}] ${reason}`
          : undefined,
      })
      .eq('id', memberId)
      .eq('gym_id', adminGymId)

    if (profileUpdateError) {
      return json({ error: profileUpdateError.message }, 400)
    }

    const { data: activeMemberships, error: membershipsError } = await adminClient
      .from('member_memberships')
      .select('id')
      .eq('member_id', memberId)
      .eq('status', 'active')

    if (membershipsError) {
      return json({ error: membershipsError.message }, 400)
    }

    let expiredMemberships = 0
    const membershipIds = (activeMemberships ?? [])
      .map((row) => (row.id ?? '').toString())
      .filter(Boolean)

    if (membershipIds.length > 0) {
      const { error: expireError } = await adminClient
        .from('member_memberships')
        .update({
          status: 'expired',
          auto_renew: false,
          end_date: today,
          current_period_end: today,
          updated_at: nowIso,
        })
        .in('id', membershipIds)

      if (expireError) {
        return json({ error: expireError.message }, 400)
      }

      expiredMemberships = membershipIds.length
    }

    const { data: futureBookings, error: bookingsError } = await adminClient
      .from('class_bookings')
      .select(`
        id,
        class_id,
        status,
        classes!inner(
          id,
          gym_id,
          starts_at
        )
      `)
      .eq('member_id', memberId)
      .eq('status', 'booked')
      .eq('classes.gym_id', adminGymId)
      .gt('classes.starts_at', nowIso)

    if (bookingsError) {
      return json({ error: bookingsError.message }, 400)
    }

    const bookingIds = (futureBookings ?? [])
      .map((row) => (row.id ?? '').toString())
      .filter(Boolean)

    let cancelledBookings = 0
    if (bookingIds.length > 0) {
      const { error: cancelError } = await adminClient
        .from('class_bookings')
        .update({
          status: 'cancelled',
        })
        .in('id', bookingIds)

      if (cancelError) {
        return json({ error: cancelError.message }, 400)
      }

      cancelledBookings = bookingIds.length
    }

    return json({
      ok: true,
      memberId,
      expired_memberships: expiredMemberships,
      cancelled_future_bookings: cancelledBookings,
    })
  } catch (e) {
    return json(
      { error: e instanceof Error ? e.message : 'Unknown error' },
      500,
    )
  }
})