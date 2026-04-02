import { createClient } from 'npm:@supabase/supabase-js@2'

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { 'Content-Type': 'application/json' },
  })
}

const INACTIVITY_THRESHOLD_DAYS = 7

Deno.serve(async () => {
  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const internalSecret = Deno.env.get('INTERNAL_FUNCTION_SECRET')!

    const admin = createClient(supabaseUrl, serviceRoleKey)
    const now = new Date()

    const { data: profiles, error: profilesError } = await admin
      .from('profiles')
      .select('id, gym_id, full_name, is_active, role')
      .eq('is_active', true)
      .in('role', ['athlete', 'member'])

    if (profilesError) {
      return json({ error: profilesError.message }, 400)
    }

    const { data: bookings, error: bookingsError } = await admin
      .from('class_bookings')
      .select(`
        id,
        member_id,
        status,
        created_at,
        attended_at,
        class:classes(
          id,
          gym_id,
          starts_at
        )
      `)
      .neq('status', 'cancelled')

    if (bookingsError) {
      return json({ error: bookingsError.message }, 400)
    }

    const lastActivityByMember = new Map<string, Date>()

    for (const row of bookings ?? []) {
      const memberId = (row.member_id ?? '').toString().trim()
      if (!memberId) continue

      const candidates: Date[] = []

      const createdAtRaw = (row.created_at ?? '').toString().trim()
      if (createdAtRaw) {
        const createdAt = new Date(createdAtRaw)
        if (!Number.isNaN(createdAt.getTime())) candidates.push(createdAt)
      }

      const attendedAtRaw = (row.attended_at ?? '').toString().trim()
      if (attendedAtRaw) {
        const attendedAt = new Date(attendedAtRaw)
        if (!Number.isNaN(attendedAt.getTime())) candidates.push(attendedAt)
      }

      const classRow = row.class as Record<string, unknown> | null
      const startsAtRaw = (classRow?.starts_at ?? '').toString().trim()
      if (startsAtRaw) {
        const startsAt = new Date(startsAtRaw)
        if (!Number.isNaN(startsAt.getTime())) candidates.push(startsAt)
      }

      if (candidates.length === 0) continue

      const latest = candidates.sort((a, b) => b.getTime() - a.getTime())[0]
      const existing = lastActivityByMember.get(memberId)

      if (!existing || latest.getTime() > existing.getTime()) {
        lastActivityByMember.set(memberId, latest)
      }
    }

    let matched = 0
    let sent = 0
    let skipped = 0

    for (const profile of profiles ?? []) {
      const memberId = (profile.id ?? '').toString().trim()
      const gymId = (profile.gym_id ?? '').toString().trim()
      const name = (profile.full_name ?? 'Athlete').toString().trim() || 'Athlete'

      if (!memberId || !gymId) continue

      const lastActivity = lastActivityByMember.get(memberId)
      if (!lastActivity) continue

      const inactiveDays = Math.floor(
        (now.getTime() - lastActivity.getTime()) / (1000 * 60 * 60 * 24),
      )

      if (inactiveDays < INACTIVITY_THRESHOLD_DAYS) continue

      matched++

      const dayStart = new Date(now)
      dayStart.setHours(0, 0, 0, 0)
      const dayEnd = new Date(now)
      dayEnd.setHours(23, 59, 59, 999)

      const { data: existing, error: existingError } = await admin
        .from('notifications')
        .select('id')
        .eq('gym_id', gymId)
        .eq('type', 'announcement')
        .contains('metadata', {
          pushType: 'inactivity_warning',
          memberId,
          inactiveDays: String(INACTIVITY_THRESHOLD_DAYS),
        })
        .gte('created_at', dayStart.toISOString())
        .lte('created_at', dayEnd.toISOString())
        .limit(1)

      if (existingError) {
        return json({ error: existingError.message }, 400)
      }

      if ((existing ?? []).length > 0) {
        skipped++
        continue
      }

      const title = 'We miss you 💪'
      const message =
        'It’s been a few days since your last class. Book your next session and get back in.'

      const { data: notification, error: notificationError } = await admin
        .from('notifications')
        .insert({
          gym_id: gymId,
          created_by: null,
          type: 'announcement',
          status: 'sent',
          title,
          message,
          recipients_scope: 'athletes',
          metadata: {
            pushType: 'inactivity_warning',
            memberId,
            memberName: name,
            inactiveDays: String(INACTIVITY_THRESHOLD_DAYS),
            targetTab: 'booking',
          },
        })
        .select('id')
        .single()

      if (notificationError || !notification) {
        return json({
          error:
            notificationError?.message ??
            'Could not create inactivity notification',
        }, 400)
      }

      const { error: userNotificationError } = await admin
        .from('user_notifications')
        .insert({
          member_id: memberId,
          notification_id: notification.id,
          is_read: false,
        })

      if (userNotificationError) {
        return json({ error: userNotificationError.message }, 400)
      }

      const pushRes = await fetch(`${supabaseUrl}/functions/v1/send-push`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-internal-function-secret': internalSecret,
        },
        body: JSON.stringify({
          userIds: [memberId],
          title,
          message,
          data: {
            type: 'inactivity_warning',
            pushType: 'inactivity_warning',
            notificationId: notification.id.toString(),
            memberId,
            inactiveDays: String(INACTIVITY_THRESHOLD_DAYS),
            targetTab: 'booking',
          },
        }),
      })

      if (!pushRes.ok) {
        const txt = await pushRes.text()
        return json({ error: `Inactivity push failed: ${txt}` }, 400)
      }

      sent++
    }

    return json({
      ok: true,
      thresholdDays: INACTIVITY_THRESHOLD_DAYS,
      matched,
      sent,
      skipped,
    })
  } catch (e) {
    return json(
      { error: e instanceof Error ? e.message : 'Unknown error' },
      500,
    )
  }
})
