import { createClient } from 'npm:@supabase/supabase-js@2'
import { sendFcmPush } from '../_shared/push.ts'

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
      return json({ error: 'Only admins can send push notifications' }, 403)
    }

    const body = await req.json()

    const title = (body.title ?? '').toString().trim()
    const message = (body.message ?? body.body ?? '').toString().trim()
    const userIds = Array.isArray(body.userIds)
      ? body.userIds.map((x: unknown) => String(x).trim()).filter(Boolean)
      : []
    const data =
      body.data && typeof body.data === 'object'
        ? Object.fromEntries(
            Object.entries(body.data).map(([k, v]) => [String(k), String(v)]),
          )
        : {}

    if (!title) return json({ error: 'title is required' }, 400)
    if (!message) return json({ error: 'message is required' }, 400)
    if (userIds.length === 0) return json({ error: 'userIds is required' }, 400)

    const { data: targetProfiles, error: targetProfilesError } = await adminClient
      .from('profiles')
      .select('id, gym_id')
      .in('id', userIds)

    if (targetProfilesError) {
      return json({ error: targetProfilesError.message }, 400)
    }

    const allowedUserIds = (targetProfiles ?? [])
      .filter((p) => p.gym_id === me.gym_id)
      .map((p) => p.id)

    if (allowedUserIds.length === 0) {
      return json({ error: 'No valid users found in your gym' }, 400)
    }

    const { data: deviceTokens, error: tokensError } = await adminClient
      .from('device_tokens')
      .select('id, member_id, token, platform')
      .in('member_id', allowedUserIds)

    if (tokensError) {
      return json({ error: tokensError.message }, 400)
    }

    const tokens = (deviceTokens ?? [])
      .map((row) => (row.token ?? '').toString().trim())
      .filter(Boolean)

    if (tokens.length === 0) {
      return json({
        ok: true,
        sent: 0,
        failed: 0,
        message: 'No device tokens found',
      })
    }

    const result = await sendFcmPush({
      tokens,
      title,
      body: message,
      data,
    })

    return json({
      ok: true,
      requestedUsers: userIds.length,
      matchedUsers: allowedUserIds.length,
      tokensFound: tokens.length,
      sent: result.sent.length,
      failed: result.failed.length,
      failures: result.failed,
    })
  } catch (e) {
    return json(
      { error: e instanceof Error ? e.message : 'Unknown error' },
      500,
    )
  }
})
