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
      return json({ error: 'Only owners can invite gym admins' }, 403)
    }

    const body = await req.json()
    const gymId = (body.gymId ?? '').toString().trim()
    const fullName = (body.fullName ?? '').toString().trim()
    const email = (body.email ?? '').toString().trim().toLowerCase()

    if (!gymId) {
      return json({ error: 'gymId is required' }, 400)
    }

    if (!fullName) {
      return json({ error: 'Full name is required' }, 400)
    }

    if (!email) {
      return json({ error: 'Email is required' }, 400)
    }

    const { data: gym, error: gymError } = await adminClient
      .from('gyms')
      .select('id, name, slug')
      .eq('id', gymId)
      .maybeSingle()

    if (gymError || !gym) {
      return json({ error: 'Gym not found' }, 404)
    }

    const { data: existingUsers, error: listError } =
      await adminClient.auth.admin.listUsers()

    if (listError) {
      return json({ error: listError.message }, 400)
    }

    const alreadyExists = existingUsers.users.some(
      (u) => (u.email ?? '').toLowerCase() === email,
    )

    if (alreadyExists) {
      return json({ error: 'Ya existe un usuario con ese email' }, 409)
    }

    const { data: invitedUser, error: inviteError } =
      await adminClient.auth.admin.inviteUserByEmail(email, {
        data: {
          full_name: fullName,
        },
        redirectTo: 'athletelab://auth',
      })

    if (inviteError || !invitedUser.user) {
      return json(
        { error: inviteError?.message ?? 'Could not invite admin' },
        400,
      )
    }

    const userId = invitedUser.user.id

    const profilePayload: Record<string, unknown> = {
      id: userId,
      gym_id: gymId,
      role: 'admin',
      full_name: fullName,
      email,
      member_since: new Date().toISOString().slice(0, 10),
      is_active: true,
    }

    const { data: existingProfile, error: existingProfileError } =
      await adminClient
        .from('profiles')
        .select('id')
        .eq('id', userId)
        .maybeSingle()

    if (existingProfileError) {
      return json({ error: existingProfileError.message }, 400)
    }

    let profileError = null

    if (existingProfile) {
      const result = await adminClient
        .from('profiles')
        .update(profilePayload)
        .eq('id', userId)
      profileError = result.error
    } else {
      const result = await adminClient
        .from('profiles')
        .insert(profilePayload)
      profileError = result.error
    }

    if (profileError) {
      return json({ error: profileError.message }, 400)
    }

    return json({
      ok: true,
      invited: true,
      gymId,
      userId,
      email,
    })
  } catch (e) {
    return json(
      { error: e instanceof Error ? e.message : 'Unknown error' },
      500,
    )
  }
})
