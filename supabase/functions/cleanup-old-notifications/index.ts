import { createClient } from 'npm:@supabase/supabase-js@2'

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { 'Content-Type': 'application/json' },
  })
}

Deno.serve(async () => {
  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''

    if (!supabaseUrl || !serviceRoleKey) {
      return json({ error: 'Missing Supabase environment variables' }, 500)
    }

    const admin = createClient(supabaseUrl, serviceRoleKey)

    const cutoff = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString()

    const { data: oldNotifications, error: fetchError } = await admin
      .from('notifications')
      .select('id')
      .eq('status', 'sent')
      .lt('updated_at', cutoff)

    if (fetchError) {
      return json({ error: fetchError.message }, 400)
    }

    const ids = (oldNotifications ?? []).map((row) => row.id).filter(Boolean)

    if (ids.length === 0) {
      return json({ ok: true, deleted_notifications: 0, deleted_user_notifications: 0 })
    }

    const { error: deleteUserError, count: deletedUserNotifications } = await admin
      .from('user_notifications')
      .delete({ count: 'exact' })
      .in('notification_id', ids)

    if (deleteUserError) {
      return json({ error: deleteUserError.message }, 400)
    }

    const { error: deleteNotificationsError, count: deletedNotifications } = await admin
      .from('notifications')
      .delete({ count: 'exact' })
      .in('id', ids)

    if (deleteNotificationsError) {
      return json({ error: deleteNotificationsError.message }, 400)
    }

    return json({
      ok: true,
      deleted_notifications: deletedNotifications ?? ids.length,
      deleted_user_notifications: deletedUserNotifications ?? 0,
    })
  } catch (error) {
    return json(
      { error: error instanceof Error ? error.message : 'Unknown error' },
      500,
    )
  }
})
