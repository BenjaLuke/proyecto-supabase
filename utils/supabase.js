import { createClient } from '@supabase/supabase-js'

export const supabase = createClient(
  import.meta.env.NUXT_PUBLIC_SUPABASE_URL,
  import.meta.env.NUXT_PUBLIC_SUPABASE_KEY
)