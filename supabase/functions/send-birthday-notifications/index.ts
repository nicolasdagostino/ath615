import { createClient } from 'npm:@supabase/supabase-js@2'

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { 'Content-Type': 'application/json' },
  })
}

function madridNow() {
  const parts = new Intl.DateTimeFormat('en-CA', {
    timeZone: 'Europe/Madrid',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).formatToParts(new Date())

  const year = Number(parts.find((p) => p.type === 'year')?.value ?? '0')
  const month = Number(parts.find((p) => p.type === 'month')?.value ?? '0')
  const day = Number(parts.find((p) => p.type === 'day')?.value ?? '0')

  return { year, month, day, iso: `${year}-${String(month).padStart(2, '0')}-${String(day).padStart(2, '0')}` }
}

Deno.serve(async (_req) => {
  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const internalSecret = Deno.env.get('INTERNAL_FUNCTION_SECRET')!

    const adminClient = createClient(supabaseUrl, serviceRoleKey)
    const today = madridNow()

    const { data: profiles, error: profilesError } = await adminClient
      .from('profiles')
      .select('id, gym_id, full_name, date_of_birth, is_active, role')
      .eq('is_active', true)
      .in('role', ['athlete', 'member'])

    if (profilesError) {
      return json({ error: profilesError.message }, 400)
    }

    const birthdayProfiles = (profiles ?? []).filter((row) => {
      const raw = (row.date_of_birth ?? '').toString().trim()
      if (!raw) return false
      const parsed = new Date(raw)
      if (Number.isNaN(parsed.getTime())) return false
      return parsed.getUTCMonth() + 1 === today.month && parsed.getUTCDate() === today.day
    })

    let sent = 0
    let skipped = 0

    for (const profile of birthdayProfiles) {
      const name = (profile.full_name ?? 'Athlete').toString().trim() || 'Athlete'
      const title = `Happy birthday, ${name}!`
      const message =
        'We hope you have an amazing day. Enjoy your training and celebrate big 🎉'

      const dayStart = `${today.iso}T00:00:00`
      const dayEnd = `${today.iso}T23:59:59`

      const { data: existing, error: existingError } = await adminClient
        .from('notifications')
        .select('id, title, created_at')
        .eq('gym_id', profile.gym_id)
        .eq('type', 'announcement')
        .eq('title', title)
        .gte('created_at', dayStart)
        .lte('created_at', dayEnd)
        .limit(1)

      if (existingError) {
        return json({ error: existingError.message }, 400)
      }

      if ((existing ?? []).length > 0) {
        skipped++
        continue
      }

      const { data: notification, error: notificationError } = await adminClient
        .from('notifications')
        .insert({
          gym_id: profile.gym_id,
          created_by: null,
          type: 'announcement',
          status: 'sent',
          title,
          message,
          recipients_scope: 'athletes',
          scheduled_for: `${today.iso}T09:00:00`,
          metadata: {
            pushType: 'birthday',
            memberId: profile.id.toString(),
            memberName: name,
            birthdayDate: today.iso,
          },
        })
        .select('id')
        .single()

      if (notificationError || !notification) {
        return json({ error: notificationError?.message ?? 'Could not create birthday notification' }, 400)
      }

      const { error: userNotificationError } = await adminClient
        .from('user_notifications')
        .insert({
          member_id: profile.id,
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
          userIds: [profile.id],
          title,
          message,
          data: {
            type: 'birthday',
            pushType: 'birthday',
            notificationId: notification.id.toString(),
            memberId: profile.id.toString(),
            memberName: name,
            birthdayDate: today.iso,
          },
        }),
      })

      if (!pushRes.ok) {
        const txt = await pushRes.text()
        return json({ error: `Birthday push failed: ${txt}` }, 400)
      }

      sent++
    }

    return json({
      ok: true,
      today: today.iso,
      matched: birthdayProfiles.length,
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
