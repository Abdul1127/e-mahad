import { createClient } from "@supabase/supabase-js";

function getSupabaseAdminEnvironment() {
  const supabaseUrl =
    process.env.NEXT_PUBLIC_SUPABASE_URL;

  const supabaseSecretKey =
    process.env.SUPABASE_SECRET_KEY ??
    process.env.SUPABASE_SERVICE_ROLE_KEY;

  if (!supabaseUrl) {
    throw new Error(
      "NEXT_PUBLIC_SUPABASE_URL belum tersedia.",
    );
  }

  if (!supabaseSecretKey) {
    throw new Error(
      "SUPABASE_SECRET_KEY atau SUPABASE_SERVICE_ROLE_KEY belum tersedia.",
    );
  }

  return {
    supabaseUrl,
    supabaseSecretKey,
  };
}

export function createAdminClient() {
  const {
    supabaseUrl,
    supabaseSecretKey,
  } = getSupabaseAdminEnvironment();

  return createClient(
    supabaseUrl,
    supabaseSecretKey,
    {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
        detectSessionInUrl: false,
      },
    },
  );
}