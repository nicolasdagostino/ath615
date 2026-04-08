import { createClient } from 'npm:@supabase/supabase-js@2'

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { 'Content-Type': 'application/json' },
  })
}

function startOfWeek(date: Date) {
  const local = new Date(date)
  const day = local.getDay()
  const diff = day === 0 ? -6 : 1 - day
  local.setHours(0, 0, 0, 0)
  local.setDate(local.getDate() + diff)
  return local
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
      return json({ error: 'Only owners can read gym metrics' }, 403)
    }

    const now = new Date()
    const weekStart = startOfWeek(now)
    const weekEnd = new Date(weekStart)
    weekEnd.setDate(weekEnd.getDate() + 7)

    const weekStartIso = weekStart.toISOString()
    const weekEndIso = weekEnd.toISOString()

    const { data: gyms, error: gymsError } = await adminClient
      .from('gyms')
      .select(
        'id, name, slug, created_at, is_active, is_blocked, blocked_reason, blocked_at, deleted_at',
      )
      .order('created_at', { ascending: false })

    if (gymsError) {
      return json({ error: gymsError.message }, 400)
    }

    const gymIds = (gyms ?? []).map((g) => g.id).filter(Boolean)

    const metricsByGym = new Map<string, Record<string, number>>()
    for (const gymId of gymIds) {
      metricsByGym.set(gymId, {
        total_members: 0,
        active_members: 0,
        admins_coaches: 0,
        classes_this_week: 0,
        bookings_this_week: 0,
      })
    }

    if (gymIds.length > 0) {
      const { data: profiles, error: profilesError } = await adminClient
        .from('profiles')
        .select('id, gym_id, role, is_active')
        .in('gym_id', gymIds)

      if (profilesError) {
        return json({ error: profilesError.message }, 400)
      }

      for (const row of profiles ?? []) {
        const gymId = (row.gym_id ?? '').toString()
        const role = (row.role ?? '').toString()
        const isActive = row.is_active === true
        const metric = metricsByGym.get(gymId)
        if (!metric) continue

        if (['athlete', 'member', 'admin', 'coach'].includes(role)) {
          metric.total_members += 1
          if (isActive) {
            metric.active_members += 1
          }
        }

        if (['admin', 'coach'].includes(role)) {
          metric.admins_coaches += 1
        }
      }

      const { data: classes, error: classesError } = await adminClient
        .from('classes')
        .select('id, gym_id, starts_at, status')
        .in('gym_id', gymIds)
        .eq('status', 'scheduled')
        .gte('starts_at', weekStartIso)
        .lt('starts_at', weekEndIso)

      if (classesError) {
        return json({ error: classesError.message }, 400)
      }

      const classIdsByGym = new Map<string, string[]>()

      for (const row of classes ?? []) {
        const gymId = (row.gym_id ?? '').toString()
        const classId = (row.id ?? '').toString()
        const metric = metricsByGym.get(gymId)
        if (!metric) continue

        metric.classes_this_week += 1

        const list = classIdsByGym.get(gymId) ?? []
        if (classId) list.push(classId)
        classIdsByGym.set(gymId, list)
      }

      const allClassIds = [...classIdsByGym.values()].flat()

      if (allClassIds.length > 0) {
        const { data: bookings, error: bookingsError } = await adminClient
          .from('class_bookings')
          .select('id, class_id')
          .in('class_id', allClassIds)

        if (bookingsError) {
          return json({ error: bookingsError.message }, 400)
        }

        const gymIdByClassId = new Map<string, string>()
        for (const [gymId, classIds] of classIdsByGym.entries()) {
          for (const classId of classIds) {
            gymIdByClassId.set(classId, gymId)
          }
        }

        for (const row of bookings ?? []) {
          const classId = (row.class_id ?? '').toString()
          const gymId = gymIdByClassId.get(classId)
          if (!gymId) continue
          const metric = metricsByGym.get(gymId)
          if (!metric) continue
          metric.bookings_this_week += 1
        }
      }
    }

    const items = (gyms ?? []).map((gym) => ({
      ...gym,
      ...(metricsByGym.get(gym.id) ?? {
        total_members: 0,
        active_members: 0,
        admins_coaches: 0,
        classes_this_week: 0,
        bookings_this_week: 0,
      }),
    }))

    return json({
      ok: true,
      items,
      week_start: weekStartIso,
      week_end: weekEndIso,
    })
  } catch (e) {
    return json(
      { error: e instanceof Error ? e.message : 'Unknown error' },
      500,
    )
  }
})