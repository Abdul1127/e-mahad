type PublicEnvironment = {
  appUrl: string;
  supabaseUrl: string;
  supabaseAnonKey: string;
};

function requireEnvironmentVariable(
  name: string,
  value: string | undefined,
): string {
  const normalizedValue = value?.trim();

  if (!normalizedValue) {
    throw new Error(
      `Environment variable ${name} belum diisi. Periksa file .env.local.`,
    );
  }

  return normalizedValue;
}

export const env: PublicEnvironment = {
  appUrl: requireEnvironmentVariable(
    "NEXT_PUBLIC_APP_URL",
    process.env.NEXT_PUBLIC_APP_URL,
  ),

  supabaseUrl: requireEnvironmentVariable(
    "NEXT_PUBLIC_SUPABASE_URL",
    process.env.NEXT_PUBLIC_SUPABASE_URL,
  ),

  supabaseAnonKey: requireEnvironmentVariable(
    "NEXT_PUBLIC_SUPABASE_ANON_KEY",
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY,
  ),
};