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

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const anonKey = Deno.env.get('SUPABASE_ANON_KEY')!
    const internalSecret = Deno.env.get('INTERNAL_FUNCTION_SECRET')!

    const adminClient = createClient(supabaseUrl, serviceRoleKey)

    const internalHeader = req.headers.get('x-internal-function-secret')
    const isInternalCall =
      !!internalHeader && internalHeader === internalSecret

    let callerGymId: string | null = null

    if (!isInternalCall) {
      const authHeader = req.headers.get('Authorization')
      if (!authHeader) {
        return json({ error: 'Missing Authorization header' }, 401)
      }

      const token = authHeader.replace('Bearer ', '')
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
        return json({ error: 'Only admins can publish notifications' }, 403)
      }

      callerGymId = (me.gym_id ?? '').toString()
    }

    const body = await req.json()
    const notificationId = (body.notificationId ?? '').toString().trim()

    if (!notificationId) {
      return json({ error: 'notificationId is required' }, 400)
    }

    const { data: notification, error: notificationError } = await adminClient
      .from('notifications')
      .select('id, gym_id, title, message, recipients_scope, status, metadata')
      .eq('id', notificationId)
      .maybeSingle()

    if (notificationError || !notification) {
      return json({ error: 'Notification not found' }, 404)
    }

    if (!isInternalCall && callerGymId != notification.gym_id) {
      return json({ error: 'Notification does not belong to your gym' }, 403)
    }

    let profileQuery = adminClient
      .from('profiles')
      .select('id, role, is_active')
      .eq('gym_id', notification.gym_id)
      .eq('is_active', true)

    const scope = (notification.recipients_scope ?? 'all_users').toString()

    if (scope === 'athletes') {
      profileQuery = profileQuery.in('role', ['athlete', 'member'])
    } else {
      profileQuery = profileQuery.in('role', [
        'athlete',
        'member',
        'admin',
        'coach',
      ])
    }

    const { data: recipients, error: recipientsError } = await profileQuery

    if (recipientsError) {
      return json({ error: recipientsError.message }, 400)
    }

    const memberIds = (recipients ?? [])
      .map((row) => row.id?.toString() ?? '')
      .filter(Boolean)

    if (memberIds.length > 0) {
      const existingRows = await adminClient
        .from('user_notifications')
        .select('member_id')
        .eq('notification_id', notification.id)

      const existingMemberIds = new Set(
        ((existingRows.data ?? []) as Array<{ member_id: string | null }>)
          .map((row) => (row.member_id ?? '').toString())
          .filter(Boolean),
      )

      const rows = memberIds
        .filter((memberId) => !existingMemberIds.has(memberId))
        .map((memberId) => ({
          member_id: memberId,
          notification_id: notification.id,
          is_read: false,
        }))

      if (rows.length > 0) {
        const { error: insertError } = await adminClient
          .from('user_notifications')
          .insert(rows)

        if (insertError) {
          return json({ error: insertError.message }, 400)
        }
      }

      const pushRes = await fetch(`${supabaseUrl}/functions/v1/send-push`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-internal-function-secret': internalSecret,
        },
        body: JSON.stringify({
          userIds: memberIds,
          // 🔥 Enriched push title
          ...(function() {
            const metadata = (notification.metadata ?? {}) as Record<string, unknown>

            const programName =
              (metadata.programName ?? '').toString().trim()

            const workoutTitle =
              (metadata.workoutTitle ?? '').toString().trim()

            const fallbackTitle =
              (notification.title ?? 'Workout').toString().trim()

            let finalTitle = ''

            if (programName && workoutTitle) {
              finalTitle = `${programName} · ${workoutTitle}`
            } else if (workoutTitle) {
              finalTitle = workoutTitle
            } else if (programName) {
              finalTitle = programName
            } else {
              finalTitle = fallbackTitle
            }

            return {
              title: finalTitle,
              message: notification.message,
            }
          })(),
          data: {
            type:
              ((notification.metadata ?? {}) as Record<string, unknown>).pushType
                ?.toString()
                ?.trim() ||
              (scope === 'athletes' ? 'announcement' : 'notification'),
            notificationId: notification.id.toString(),
            workoutId:
              ((notification.metadata ?? {}) as Record<string, unknown>).workoutId
                ?.toString()
                ?.trim() || '',
            programId:
              ((notification.metadata ?? {}) as Record<string, unknown>).programId
                ?.toString()
                ?.trim() || '',
            programName:
              ((notification.metadata ?? {}) as Record<string, unknown>).programName
                ?.toString()
                ?.trim() || '',
            workoutDate:
              ((notification.metadata ?? {}) as Record<string, unknown>).workoutDate
                ?.toString()
                ?.trim() || '',
          },
        }),
      })

      if (!pushRes.ok) {
        const text = await pushRes.text()
        return json({ error: `Push invoke failed: ${text}` }, 400)
      }
    }

    await adminClient
      .from('notifications')
      .update({ status: 'sent' })
      .eq('id', notification.id)

    return json({
      ok: true,
      notificationId: notification.id,
      recipients: memberIds.length,
    })
  } catch (e) {
    return json(
      { error: e instanceof Error ? e.message : 'Unknown error' },
      500,
    )
  }
})
