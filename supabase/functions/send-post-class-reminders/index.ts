import { createClient } from 'npm:@supabase/supabase-js@2'

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { 'Content-Type': 'application/json' },
  })
}

Deno.serve(async () => {
  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const internalSecret = Deno.env.get('INTERNAL_FUNCTION_SECRET')!

    const admin = createClient(supabaseUrl, serviceRoleKey)
    const now = new Date()
    const windowStart = new Date(now.getTime() - 3 * 60 * 60 * 1000) // last 3h

    const { data: rows, error } = await admin
      .from('class_bookings')
      .select(`
        id,
        member_id,
        status,
        attended_at,
        class:classes(
          id,
          gym_id,
          starts_at,
          duration_minutes,
          workout_id
        )
      `)
      .neq('status', 'cancelled')

    if (error) {
      return json({ error: error.message }, 400)
    }

    let matched = 0
    let sent = 0
    let skipped = 0

    for (const row of rows ?? []) {
      const bookingId = (row.id ?? '').toString().trim()
      const memberId = (row.member_id ?? '').toString().trim()
      const classRow = row.class as Record<string, unknown> | null

      if (!bookingId || !memberId || !classRow) continue

      const classId = (classRow.id ?? '').toString().trim()
      const gymId = (classRow.gym_id ?? '').toString().trim()
      const workoutId = (classRow.workout_id ?? '').toString().trim()
      const startsAtRaw = (classRow.starts_at ?? '').toString().trim()
      const durationMinutes = Number(classRow.duration_minutes ?? 60)

      if (!classId || !gymId || !workoutId || !startsAtRaw) continue

      const start = new Date(startsAtRaw)
      if (Number.isNaN(start.getTime())) continue

      const classEnd = new Date(start.getTime() + durationMinutes * 60 * 1000)
      const sendAfter = new Date(classEnd.getTime() + 20 * 60 * 1000)

      if (now < sendAfter) continue

      // ⛔ skip old classes
      if (classEnd < windowStart) continue

      matched++

      const { data: existing, error: existingError } = await admin
        .from('notifications')
        .select('id')
        .eq('gym_id', gymId)
        .eq('type', 'announcement')
        .contains('metadata', {
          pushType: 'workout_comment_reminder',
          bookingId,
        })
        .limit(1)

      if (existingError) {
        return json({ error: existingError.message }, 400)
      }

      if ((existing ?? []).length > 0) {
        skipped++
        continue
      }

      const title = "Don’t forget your workout 💪"
      const message = 'Leave a comment and share how it went'

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
            pushType: 'workout_comment_reminder',
            workoutId,
            classId,
            bookingId,
            memberId,
          },
        })
        .select('id')
        .single()

      if (notificationError || !notification) {
        return json({
          error:
            notificationError?.message ??
            'Could not create post-class reminder notification',
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
            type: 'workout_comment_reminder',
            notificationId: notification.id.toString(),
            workoutId,
            classId,
            bookingId,
          },
        }),
      })

      if (!pushRes.ok) {
        const txt = await pushRes.text()
        return json({ error: `Post-class reminder push failed: ${txt}` }, 400)
      }

      sent++
    }

    return json({
      ok: true,
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
