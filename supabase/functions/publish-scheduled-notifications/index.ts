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

    const internalSecret = Deno.env.get('INTERNAL_FUNCTION_SECRET')!
    const headerSecret = req.headers.get('x-internal-function-secret')

    if (!headerSecret || headerSecret !== internalSecret) {
      return json({ error: 'Unauthorized internal call' }, 401)
    }


    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

    const adminClient = createClient(supabaseUrl, serviceRoleKey)

    const nowIso = new Date().toISOString()

    const { data: notifications, error: notificationsError } = await adminClient
      .from('notifications')
      .select('id, title, scheduled_for, status')
      .eq('status', 'scheduled')
      .lte('scheduled_for', nowIso)
      .order('scheduled_for', { ascending: true })
      .limit(100)

    if (notificationsError) {
      return json({ error: notificationsError.message }, 400)
    }

    let published = 0
    const errors: Array<{ id: string; error: string }> = []

    for (const notification of notifications ?? []) {
      const res = await fetch(
        `${supabaseUrl}/functions/v1/publish-notification`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'x-internal-function-secret': internalSecret,
          },
          body: JSON.stringify({
            notificationId: notification.id,
          }),
        },
      )

      if (!res.ok) {
        errors.push({
          id: notification.id.toString(),
          error: await res.text(),
        })
        continue
      }

      published++
    }

    return json({
      ok: true,
      scanned: (notifications ?? []).length,
      published,
      errors,
    })
  } catch (e) {
    return json(
      { error: e instanceof Error ? e.message : 'Unknown error' },
      500,
    )
  }
})
