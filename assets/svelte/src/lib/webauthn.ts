export type User = {
  id: number
  display_name: string
  backup_codes_remaining?: number
}

export type AuthStatus = {
  enrolled: boolean
  authenticated: boolean
  user?: User
}

function base64urlToBuffer(base64url: string): ArrayBuffer {
  const base64 = base64url.replace(/-/g, '+').replace(/_/g, '/')
  const padding = base64.length % 4 === 0 ? '' : '='.repeat(4 - (base64.length % 4))
  const binary = atob(base64 + padding)
  const bytes = new Uint8Array(binary.length)
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i)
  return bytes.buffer
}

function bufferToBase64url(buffer: ArrayBuffer): string {
  const bytes = new Uint8Array(buffer)
  let binary = ''
  for (const byte of bytes) binary += String.fromCharCode(byte)
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')
}

function decodeCreationOptions(options: Record<string, unknown>) {
  const publicKey = options.publicKey as PublicKeyCredentialCreationOptions
  return {
    publicKey: {
      ...publicKey,
      challenge: base64urlToBuffer(publicKey.challenge as unknown as string),
      user: {
        ...publicKey.user,
        id: base64urlToBuffer(publicKey.user.id as unknown as string)
      }
    }
  }
}

function decodeRequestOptions(options: Record<string, unknown>) {
  const publicKey = options.publicKey as PublicKeyCredentialRequestOptions
  const allowCredentials = publicKey.allowCredentials?.map((cred) => ({
    ...cred,
    id: base64urlToBuffer(cred.id as unknown as string)
  }))

  return {
    publicKey: {
      ...publicKey,
      challenge: base64urlToBuffer(publicKey.challenge as unknown as string),
      allowCredentials
    }
  }
}

async function request<T>(path: string, options: RequestInit = {}): Promise<T> {
  const response = await fetch(path, {
    credentials: 'include',
    headers: {
      'Content-Type': 'application/json',
      ...(options.headers ?? {})
    },
    ...options
  })

  if (!response.ok) {
    const body = await response.json().catch(() => ({}))
    throw new Error((body as { error?: string }).error ?? `Request failed: ${response.status}`)
  }

  return response.json() as Promise<T>
}

export const authApi = {
  status: () => request<AuthStatus>('/api/auth/status'),
  me: () => request<{ authenticated: boolean; enrolled: boolean; user?: User }>('/api/auth/me'),
  logout: () => request<{ ok: boolean }>('/api/auth/logout', { method: 'POST' }),

  async register(): Promise<{ user: User; backup_codes: string[] }> {
    const options = await request<Record<string, unknown>>('/api/auth/register/options', {
      method: 'POST'
    })

    const credential = (await navigator.credentials.create(
      decodeCreationOptions(options) as CredentialCreationOptions
    )) as PublicKeyCredential | null

    if (!credential) throw new Error('registration_cancelled')

    const response = credential.response as AuthenticatorAttestationResponse

    return request('/api/auth/register/verify', {
      method: 'POST',
      body: JSON.stringify({
        credential: {
          id: credential.id,
          attestationObject: bufferToBase64url(response.attestationObject),
          clientDataJSON: bufferToBase64url(response.clientDataJSON)
        }
      })
    })
  },

  async login(): Promise<{ user: User }> {
    const options = await request<Record<string, unknown>>('/api/auth/login/options', {
      method: 'POST'
    })

    const credential = (await navigator.credentials.get(
      decodeRequestOptions(options) as CredentialRequestOptions
    )) as PublicKeyCredential | null

    if (!credential) throw new Error('login_cancelled')

    const response = credential.response as AuthenticatorAssertionResponse

    return request('/api/auth/login/verify', {
      method: 'POST',
      body: JSON.stringify({
        credential: {
          id: credential.id,
          authenticatorData: bufferToBase64url(response.authenticatorData),
          clientDataJSON: bufferToBase64url(response.clientDataJSON),
          signature: bufferToBase64url(response.signature)
        }
      })
    })
  },

  backupLogin(code: string) {
    return request<{ user: User }>('/api/auth/backup', {
      method: 'POST',
      body: JSON.stringify({ code })
    })
  }
}

export function webAuthnSupported(): boolean {
  return typeof window !== 'undefined' && !!window.PublicKeyCredential
}
