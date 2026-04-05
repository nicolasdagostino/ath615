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

    const admin = createClient(supabaseUrl, serviceRoleKey)

    const { data, error } = await admin.rpc('renew_due_memberships')

    if (error) {
      return json({ error: error.message }, 400)
    }

    return json(data ?? { ok: true })
  } catch (e) {
    return json(
      { error: e instanceof Error ? e.message : 'Unknown error' },
      500,
    )
  }
})
