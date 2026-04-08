import { createClient } from 'npm:@supabase/supabase-js@2'

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { 'Content-Type': 'application/json' },
  })
}

function slugify(input: string) {
  return input
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/-+/g, '-')
    .replace(/^-|-$/g, '')
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

    if (meError || !me || me.role !== 'owner') {
      return json({ error: 'Only owners can seed test athletes' }, 403)
    }

    const body = await req.json()
    const countRaw = Number(body.count ?? 10)
    const password = (body.password ?? 'Prueba5-').toString()
    const gymId = (body.gymId ?? '').toString().trim()

    if (!gymId) {
      return json({ error: 'gymId is required' }, 400)
    }

    const count = Number.isFinite(countRaw) ? Math.max(1, Math.min(50, countRaw)) : 10

    const { data: gym, error: gymError } = await adminClient
      .from('gyms')
      .select('id, name, slug')
      .eq('id', gymId)
      .maybeSingle()

    if (gymError || !gym) {
      return json({ error: 'Gym not found' }, 404)
    }

    const gymSlug = slugify((gym.slug ?? gym.name ?? 'gym').toString()) || 'gym'
    const created: Array<Record<string, unknown>> = []
    const skipped: Array<Record<string, unknown>> = []

    for (let i = 1; i <= count; i++) {
      const email = `${gymSlug}-athlete-${i}@athletelab.local`
      const fullName = `${(gym.name ?? 'Gym').toString().trim()} Athlete ${i}`

      const { data: existingUsers, error: listError } =
        await adminClient.auth.admin.listUsers()

      if (listError) {
        return json({ error: listError.message }, 400)
      }

      const existingUser = existingUsers.users.find(
        (u) => (u.email ?? '').toLowerCase() === email.toLowerCase(),
      )

      let userId = ''

      if (existingUser) {
        userId = existingUser.id
        skipped.push({
          email,
          reason: 'auth user already exists',
        })
      } else {
        const { data: createdUser, error: createUserError } =
          await adminClient.auth.admin.createUser({
            email,
            password,
            email_confirm: true,
            user_metadata: {
              full_name: fullName,
              seeded: true,
              seed_type: 'athlete',
            },
          })

        if (createUserError || !createdUser.user) {
          skipped.push({
            email,
            reason: createUserError?.message ?? 'could not create auth user',
          })
          continue
        }

        userId = createdUser.user.id
      }

      if (!userId) continue

      const profilePayload: Record<string, unknown> = {
        id: userId,
        gym_id: gymId,
        role: 'athlete',
        full_name: fullName,
        email,
        member_since: new Date().toISOString().slice(0, 10),
        is_active: true,
        notes: 'Seeded test athlete',
      }

      const { data: existingProfile, error: existingProfileError } =
        await adminClient
          .from('profiles')
          .select('id')
          .eq('id', userId)
          .maybeSingle()

      if (existingProfileError) {
        skipped.push({
          email,
          reason: existingProfileError.message,
        })
        continue
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
        skipped.push({
          email,
          reason: profileError.message,
        })
        continue
      }

      created.push({
        id: userId,
        email,
        full_name: fullName,
      })
    }

    return json({
      ok: true,
      gym: {
        id: gym.id,
        name: gym.name,
        slug: gym.slug,
      },
      password,
      requested_count: count,
      created_count: created.length,
      skipped_count: skipped.length,
      created,
      skipped,
    })
  } catch (e) {
    return json(
      { error: e instanceof Error ? e.message : 'Unknown error' },
      500,
    )
  }
})