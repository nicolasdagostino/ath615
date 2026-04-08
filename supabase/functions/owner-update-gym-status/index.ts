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
      .select('id, role')
      .eq('id', user.id)
      .maybeSingle()

    if (meError || !me) {
      return json({ error: 'Profile not found' }, 404)
    }

    if (me.role !== 'owner') {
      return json({ error: 'Only owners can update gym status' }, 403)
    }

    const body = await req.json()
    const gymId = (body.gymId ?? '').toString().trim()
    const action = (body.action ?? '').toString().trim().toLowerCase()
    const reason = (body.reason ?? '').toString().trim()

    if (!gymId) {
      return json({ error: 'gymId is required' }, 400)
    }

    if (!action) {
      return json({ error: 'action is required' }, 400)
    }

    const allowed = new Set([
      'activate',
      'deactivate',
      'block',
      'unblock',
      'archive',
      'restore',
    ])

    if (!allowed.has(action)) {
      return json({ error: 'Invalid action' }, 400)
    }

    const { data: existingGym, error: gymError } = await adminClient
      .from('gyms')
      .select(
        'id, name, slug, is_active, is_blocked, blocked_reason, blocked_at, deleted_at',
      )
      .eq('id', gymId)
      .maybeSingle()

    if (gymError || !existingGym) {
      return json({ error: 'Gym not found' }, 404)
    }

    const now = new Date().toISOString()
    const payload: Record<string, unknown> = {}

    switch (action) {
      case 'activate':
        payload.is_active = true
        break
      case 'deactivate':
        payload.is_active = false
        break
      case 'block':
        payload.is_blocked = true
        payload.blocked_at = now
        payload.blocked_reason = reason || null
        break
      case 'unblock':
        payload.is_blocked = false
        payload.blocked_at = null
        payload.blocked_reason = null
        break
      case 'archive':
        payload.deleted_at = now
        break
      case 'restore':
        payload.deleted_at = null
        break
    }

    const { data: updatedGym, error: updateError } = await adminClient
      .from('gyms')
      .update(payload)
      .eq('id', gymId)
      .select(
        'id, name, slug, is_active, is_blocked, blocked_reason, blocked_at, deleted_at',
      )
      .single()

    if (updateError || !updatedGym) {
      return json(
        { error: updateError?.message ?? 'Could not update gym status' },
        400,
      )
    }

    return json({
      ok: true,
      action,
      gym: updatedGym,
    })
  } catch (e) {
    return json(
      { error: e instanceof Error ? e.message : 'Unknown error' },
      500,
    )
  }
})