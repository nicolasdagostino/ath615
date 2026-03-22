import { createClient } from 'npm:@supabase/supabase-js@2'

Deno.serve(async (req) => {
  try {
    if (req.method !== 'POST') {
      return new Response(
        JSON.stringify({ error: 'Method not allowed' }),
        {
          status: 405,
          headers: { 'Content-Type': 'application/json' },
        },
      )
    }

    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Missing Authorization header' }),
        {
          status: 401,
          headers: { 'Content-Type': 'application/json' },
        },
      )
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
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        {
          status: 401,
          headers: { 'Content-Type': 'application/json' },
        },
      )
    }

    const { data: me, error: meError } = await adminClient
      .from('profiles')
      .select('id, role, gym_id')
      .eq('id', user.id)
      .maybeSingle()

    if (meError || !me || me.role !== 'admin') {
      return new Response(
        JSON.stringify({ error: 'Only admins can create members' }),
        {
          status: 403,
          headers: { 'Content-Type': 'application/json' },
        },
      )
    }

    const body = await req.json()

    const fullName = (body.fullName ?? '').toString().trim()
    const email = (body.email ?? '').toString().trim().toLowerCase()
    const role = (body.role ?? 'athlete').toString().trim()
    const phone = (body.phone ?? '').toString().trim()
    const dateOfBirth = (body.dateOfBirth ?? '').toString().trim()
    const notes = (body.notes ?? '').toString().trim()
    const isActive = body.isActive == null ? true : body.isActive === true

    if (!fullName) {
      return new Response(
        JSON.stringify({ error: 'Full name is required' }),
        {
          status: 400,
          headers: { 'Content-Type': 'application/json' },
        },
      )
    }

    if (!email) {
      return new Response(
        JSON.stringify({ error: 'Email is required' }),
        {
          status: 400,
          headers: { 'Content-Type': 'application/json' },
        },
      )
    }

    const { data: existingUsers, error: listError } =
      await adminClient.auth.admin.listUsers()

    if (listError) {
      return new Response(
        JSON.stringify({ error: listError.message }),
        {
          status: 400,
          headers: { 'Content-Type': 'application/json' },
        },
      )
    }

    const alreadyExists = existingUsers.users.some(
      (u) => (u.email ?? '').toLowerCase() === email,
    )

    if (alreadyExists) {
      return new Response(
        JSON.stringify({ error: 'Ya existe un usuario con ese email' }),
        {
          status: 409,
          headers: { 'Content-Type': 'application/json' },
        },
      )
    }

    const { data: invitedUser, error: inviteError } =
      await adminClient.auth.admin.inviteUserByEmail(email, {
        data: {
          full_name: fullName,
        },
        redirectTo: 'athletelab://auth',
      })

    if (inviteError || !invitedUser.user) {
      return new Response(
        JSON.stringify({
          error: inviteError?.message ?? 'Could not invite user',
        }),
        {
          status: 400,
          headers: { 'Content-Type': 'application/json' },
        },
      )
    }

    const userId = invitedUser.user.id

    const profilePayload: Record<string, unknown> = {
      id: userId,
      gym_id: me.gym_id,
      role,
      full_name: fullName,
      email,
      phone: phone || null,
      date_of_birth: dateOfBirth || null,
      member_since: new Date().toISOString().slice(0, 10),
      is_active: isActive,
      notes: notes || null,
    }

    const { data: existingProfile, error: existingProfileError } =
      await adminClient
        .from('profiles')
        .select('id')
        .eq('id', userId)
        .maybeSingle()

    if (existingProfileError) {
      return new Response(
        JSON.stringify({ error: existingProfileError.message }),
        {
          status: 400,
          headers: { 'Content-Type': 'application/json' },
        },
      )
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
      return new Response(
        JSON.stringify({ error: profileError.message }),
        {
          status: 400,
          headers: { 'Content-Type': 'application/json' },
        },
      )
    }

    return new Response(
      JSON.stringify({
        ok: true,
        invited: true,
        userId,
        email,
      }),
      {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      },
    )
  } catch (e) {
    return new Response(
      JSON.stringify({
        error: e instanceof Error ? e.message : 'Unknown error',
      }),
      {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      },
    )
  }
})
