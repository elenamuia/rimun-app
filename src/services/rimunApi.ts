export const RIMUN_API_BASE =
  (import.meta as any).env?.VITE_RIMUN_API_URL ?? "http://127.0.0.1:8081";

async function getJSON<T>(path: string): Promise<T> {
  const res = await fetch(`${RIMUN_API_BASE}${path}`);
  if (!res.ok) {
    const text = await res.text().catch(() => "");
    throw new Error(`API ${path} failed: ${res.status} ${text}`);
  }
  return res.json() as Promise<T>;
}

export type Forum = {
  id: number;
  acronym: string;
  name: string;
  description: string | null;
  image_path: string | null;
  created_at: string;
  updated_at: string;
};

export type Delegate = {
  person_id: number;
  name: string;
  surname: string;
  full_name: string;
  birthday: string | null;
  gender: string | null;
  picture_path: string | null;
  phone_number: string | null;
  allergies: string | null;
  country_code: string;
  country_name: string;
  session_id: number;
  session_edition: number;
  committee_id: number | null;
  committee_name: string | null;
  forum_acronym: string | null;
  delegation_id: number | null;
  delegation_name: string | null;
  school_id: number | null;
  school_name: string | null;
  role_confirmed: string | null;
  role_requested: string | null;
  group_confirmed: string | null;
  group_requested: string | null;
  status_application: string;
  status_housing: string;
  is_ambassador: boolean | null;
  housing_is_available: boolean;
  housing_n_guests: number | null;
  updated_at: string;
  created_at: string;
};

export type ListDelegatesParams = {
  session_id?: number;
  delegation_id?: number;
  committee_id?: number;
  country_code?: string;
  school_id?: number;
  status_application?: string;
  status_housing?: string;
  is_ambassador?: boolean;
  updated_since?: string; // ISO datetime
  limit?: number;
  offset?: number;
};

const qs = (params: Record<string, unknown>) =>
  Object.entries(params)
    .filter(([, v]) => v !== undefined && v !== null && v !== "")
    .map(([k, v]) => `${encodeURIComponent(k)}=${encodeURIComponent(String(v))}`)
    .join("&");

export const api = {
  health: () => getJSON<{ status: string }>("/health"),
  forums: () => getJSON<Forum[]>("/forums"),
  committees: (limit = 50, offset = 0) =>
    getJSON<any[]>(`/committees?limit=${limit}&offset=${offset}`),
  sessions: (active?: boolean, limit = 50, offset = 0) =>
    getJSON<any[]>(`/sessions?${qs({ active, limit, offset })}`),
  posts: (limit = 50, offset = 0) =>
    getJSON<any[]>(`/posts?limit=${limit}&offset=${offset}`),
  delegates: (params: ListDelegatesParams = {}) => {
    const query = qs({ limit: 50, offset: 0, ...params });
    return getJSON<Delegate[]>(`/delegates?${query}`);
  },
  delegateById: (personId: number) =>
    getJSON<Delegate | Record<string, never>>(`/delegates/${personId}`),
};
