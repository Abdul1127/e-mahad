"use server";

import { revalidatePath } from "next/cache";
import { cookies } from "next/headers";
import { redirect } from "next/navigation";

import { ACTIVE_ROLE_COOKIE_NAME } from "@/lib/auth/constants";
import { createClient } from "@/lib/supabase/server";

export async function logoutAction(): Promise<void> {
  const supabase = await createClient();

  await supabase.auth.signOut();

  const cookieStore = await cookies();

  cookieStore.delete(ACTIVE_ROLE_COOKIE_NAME);

  revalidatePath("/", "layout");

  redirect("/login");
}