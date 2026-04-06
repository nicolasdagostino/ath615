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
      .select('id, role, gym_id, full_name, email')
      .eq('id', user.id)
      .maybeSingle()

    if (meError || !me) {
      return json({ error: 'Profile not found' }, 404)
    }

    if (me.role !== 'owner') {
      return json({ error: 'Only owners can create gyms' }, 403)
    }

    const body = await req.json()
    const name = (body.name ?? '').toString().trim()
    const rawSlug = (body.slug ?? '').toString().trim()
    const slug = slugify(rawSlug)

    if (!name) {
      return json({ error: 'Gym name is required' }, 400)
    }

    if (!slug) {
      return json({ error: 'Gym slug is required' }, 400)
    }

    const { data: existingGym, error: existingGymError } = await adminClient
      .from('gyms')
      .select('id')
      .eq('slug', slug)
      .maybeSingle()

    if (existingGymError) {
      return json({ error: existingGymError.message }, 400)
    }

    if (existingGym) {
      return json({ error: 'A gym with this slug already exists' }, 409)
    }

    const { data: gym, error: gymError } = await adminClient
      .from('gyms')
      .insert({
        name,
        slug,
      })
      .select('id, name, slug')
      .single()

    if (gymError || !gym) {
      return json({ error: gymError?.message ?? 'Could not create gym' }, 400)
    }

    return json({
      ok: true,
      gym,
      promoted_to_admin: false,
    })
  } catch (e) {
    return json(
      { error: e instanceof Error ? e.message : 'Unknown error' },
      500,
    )
  }
})
