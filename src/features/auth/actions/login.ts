"use server";

import { revalidatePath } from "next/cache";
import { cookies } from "next/headers";
import { redirect } from "next/navigation";

import { roleDefinitions } from "@/config/roles";
import { ACTIVE_ROLE_COOKIE_NAME } from "@/lib/auth/constants";
import { getAccessContextWithClient } from "@/lib/auth/get-access-context";
import { createClient } from "@/lib/supabase/server";

import { loginSchema } from "../schemas/login-schema";
import type { LoginActionState } from "../types/login-action-state";

export async function loginAction(
  _previousState: LoginActionState,
  formData: FormData,
): Promise<LoginActionState> {
  const validationResult = loginSchema.safeParse({
    email: formData.get("email"),
    password: formData.get("password"),
  });

  if (!validationResult.success) {
    const fieldErrors =
      validationResult.error.flatten().fieldErrors;

    return {
      status: "error",
      message:
        "Periksa kembali data login yang dimasukkan.",
      fieldErrors: {
        email: fieldErrors.email,
        password: fieldErrors.password,
      },
    };
  }

  const supabase = await createClient();

  const { error: loginError } =
    await supabase.auth.signInWithPassword({
      email: validationResult.data.email,
      password: validationResult.data.password,
    });

  if (loginError) {
    return {
      status: "error",
      message:
        "Email atau password tidak sesuai.",
      fieldErrors: {},
    };
  }

  let accessContext;

  try {
    accessContext =
      await getAccessContextWithClient(supabase);
  } catch (error) {
    console.error(
      "Gagal membaca akses setelah login:",
      error,
    );

    await supabase.auth.signOut();

    return {
      status: "error",
      message:
        "Akun berhasil diverifikasi, tetapi data akses tidak dapat dibaca.",
      fieldErrors: {},
    };
  }

  if (!accessContext) {
    await supabase.auth.signOut();

    return {
      status: "error",
      message:
        "Profile akun tidak ditemukan atau sesi tidak valid.",
      fieldErrors: {},
    };
  }

  if (!accessContext.isActive) {
    await supabase.auth.signOut();

    return {
      status: "error",
      message:
        "Akun sedang tidak aktif. Hubungi administrator.",
      fieldErrors: {},
    };
  }

  if (accessContext.roles.length === 0) {
    await supabase.auth.signOut();

    return {
      status: "error",
      message:
        "Akun belum mempunyai role aplikasi.",
      fieldErrors: {},
    };
  }

  const cookieStore = await cookies();

  let destination = "/select-role";

  if (accessContext.roles.length === 1) {
    const assignedRole =
      accessContext.roles[0].code;

    cookieStore.set(
      ACTIVE_ROLE_COOKIE_NAME,
      assignedRole,
      {
        httpOnly: true,
        sameSite: "lax",
        secure:
          process.env.NODE_ENV === "production",
        path: "/",
      },
    );

    destination =
      roleDefinitions[assignedRole]
        .dashboardPath;
  } else {
    cookieStore.delete(
      ACTIVE_ROLE_COOKIE_NAME,
    );
  }

  revalidatePath("/", "layout");

  redirect(destination);
}