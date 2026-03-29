import { GoogleAuth } from 'npm:google-auth-library@9'

type SendPushParams = {
  tokens: string[]
  title: string
  body: string
  data?: Record<string, string>
}

type PushResult = {
  sent: string[]
  failed: Array<{ token: string; error: string }>
}

function getFirebaseConfig() {
  const raw = Deno.env.get('FIREBASE_SERVICE_ACCOUNT_JSON')
  if (!raw) {
    throw new Error('Missing FIREBASE_SERVICE_ACCOUNT_JSON secret')
  }

  const serviceAccount = JSON.parse(raw)
  const projectId =
    Deno.env.get('FCM_PROJECT_ID') ||
    serviceAccount.project_id ||
    ''

  if (!projectId) {
    throw new Error('Missing FCM project id')
  }

  return { serviceAccount, projectId }
}

async function getAccessToken(serviceAccount: Record<string, unknown>) {
  const auth = new GoogleAuth({
    credentials: serviceAccount,
    scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
  })

  const client = await auth.getClient()
  const tokenResponse = await client.getAccessToken()
  const accessToken =
    typeof tokenResponse === 'string'
      ? tokenResponse
      : (tokenResponse?.token ?? '')

  if (!accessToken) {
    throw new Error('Could not obtain Google access token')
  }

  return accessToken
}

export async function sendFcmPush({
  tokens,
  title,
  body,
  data = {},
}: SendPushParams): Promise<PushResult> {
  const cleanedTokens = [...new Set(tokens.map((t) => t.trim()).filter(Boolean))]
  if (cleanedTokens.length === 0) {
    return { sent: [], failed: [] }
  }

  const { serviceAccount, projectId } = getFirebaseConfig()
  const accessToken = await getAccessToken(serviceAccount)

  const sent: string[] = []
  const failed: Array<{ token: string; error: string }> = []

  for (const token of cleanedTokens) {
    const res = await fetch(
      `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          message: {
            token,
            notification: {
              title,
              body,
            },
            data,
            apns: {
              payload: {
                aps: {
                  sound: 'default',
                },
              },
            },
          },
        }),
      },
    )

    if (res.ok) {
      sent.push(token)
      continue
    }

    const text = await res.text()
    failed.push({ token, error: text })
  }

  return { sent, failed }
}
