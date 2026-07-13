export type LayoutWidget = {
  id: string
  x: number
  y: number
  w: number
  h: number
  collapsed: boolean
}

export type Layout = {
  widgets: LayoutWidget[]
  columns: number
}

export type GitHubCommit = {
  id: number
  repo: string
  sha: string
  author: string | null
  message: string
  committed_at: string
}

export type RedmineIssue = {
  id: number
  issue_id: number
  title: string
  status: string | null
  assignee: string | null
  updated_at: string
}

export type RssEntry = {
  id: number
  feed_id: number
  title: string
  url: string
  summary: string | null
  published_at: string | null
  read: boolean
  saved: boolean
}

export type RssFeed = {
  id: number
  name: string
  url: string
  enabled: boolean
}

export type WeatherReading = {
  city: string
  temperature: number | null
  conditions: string | null
  humidity: number | null
  recorded_at: string | null
}

export type Activity = {
  id: number
  source: string
  source_instance: string
  type: string
  title: string
  summary: string | null
  author: string | null
  url: string | null
  occurred_at: string
}

export type User = {
  id: number
  display_name: string
  backup_codes_remaining?: number
}

export type CollectorFailure = {
  name: string
  error: string
}

export type CollectorPullResult = {
  source: string
  status: 'ok' | 'error' | 'partial' | 'skipped'
  message: string
  failures: CollectorFailure[]
}

export type CollectorPullResponse = {
  pulled_at: string
  results: CollectorPullResult[]
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
    throw new Error(`Request failed: ${response.status}`)
  }

  return response.json() as Promise<T>
}

export const api = {
  me: () =>
    request<{ authenticated: boolean; enrolled: boolean; user?: User }>('/api/auth/me'),
  layout: () => request<{ layout: Layout }>('/api/layout'),
  saveLayout: (layout: Layout) =>
    request<{ ok: boolean }>('/api/layout', {
      method: 'PUT',
      body: JSON.stringify({ layout })
    }),
  github: () => request<{ commits: GitHubCommit[] }>('/api/github'),
  redmine: (assigned = false) =>
    request<{ issues: RedmineIssue[] }>(`/api/redmine${assigned ? '?assigned=true' : ''}`),
  rss: (opts: { unread?: boolean; saved?: boolean } = {}) => {
    const params = new URLSearchParams()
    if (opts.unread) params.set('unread', 'true')
    if (opts.saved) params.set('saved', 'true')
    const query = params.toString()
    return request<{ feeds: RssFeed[]; entries: RssEntry[] }>(`/api/rss${query ? `?${query}` : ''}`)
  },
  markRssRead: (id: number) => request<{ ok: boolean }>(`/api/rss/${id}/read`, { method: 'POST' }),
  markRssSaved: (id: number, saved: boolean) =>
    request<{ ok: boolean }>(`/api/rss/${id}/saved`, {
      method: 'PUT',
      body: JSON.stringify({ saved })
    }),
  weather: () => request<{ readings: WeatherReading[] }>('/api/weather'),
  timeline: (source?: string) =>
    request<{ activities: Activity[] }>(`/api/timeline${source ? `?source=${source}` : ''}`),
  pull: () => request<CollectorPullResponse>('/api/collectors/pull', { method: 'POST' })
}

export function relativeTime(iso: string | null): string {
  if (!iso) return ''
  const date = new Date(iso)
  const seconds = Math.floor((Date.now() - date.getTime()) / 1000)
  if (seconds < 60) return 'just now'
  const minutes = Math.floor(seconds / 60)
  if (minutes < 60) return `${minutes}m ago`
  const hours = Math.floor(minutes / 60)
  if (hours < 24) return `${hours}h ago`
  const days = Math.floor(hours / 24)
  return `${days}d ago`
}
