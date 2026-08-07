"use server";

import { revalidatePath } from "next/cache";
import { cookies } from "next/headers";
import { redirect } from "next/navigation";

import { roleDefinitions } from "@/config/roles";
import { ACTIVE_ROLE_COOKIE_NAME } from "@/lib/auth/constants";
import { getAccessContextWithClient } from "@/lib/auth/get-access-context";
import { createAdminClient } from "@/lib/supabase/admin";
import { createClient } from "@/lib/supabase/server";

import { loginSchema } from "../schemas/login-schema";
import type { LoginActionState } from "../types/login-action-state";

function invalidCredentialState(): LoginActionState {
  return {
    status: "error",
    message:
      "ID Pengguna atau password tidak sesuai.",
    fieldErrors: {},
  };
}

export async function loginAction(
  _previousState: LoginActionState,
  formData: FormData,
): Promise<LoginActionState> {
  const validationResult =
    loginSchema.safeParse({
      login_id:
        formData.get("login_id"),

      password:
        formData.get("password"),
    });

  if (!validationResult.success) {
    const fieldErrors =
      validationResult.error.flatten()
        .fieldErrors;

    return {
      status: "error",

      message:
        "Periksa kembali data login yang dimasukkan.",

      fieldErrors: {
        login_id:
          fieldErrors.login_id,

        password:
          fieldErrors.password,
      },
    };
  }

  const loginId =
    validationResult.data.login_id;

  const password =
    validationResult.data.password;

  let authEmail: string;

  try {
    const adminSupabase =
      createAdminClient();

    /*
     * Login ID disimpan di public.profiles.
     * Admin Client diperlukan karena pengguna
     * belum mempunyai session ketika proses
     * login dimulai.
     */
    const {
      data: profile,
      error: profileLookupError,
    } = await adminSupabase
      .from("profiles")
      .select("id")
      .eq("login_id", loginId)
      .maybeSingle();

    if (profileLookupError) {
      console.error(
        "Gagal mencari profile berdasarkan login ID:",
        {
          loginId,
          error:
            profileLookupError.message,
        },
      );

      return {
        status: "error",

        message:
          "Layanan login sedang mengalami kendala. Silakan coba kembali.",

        fieldErrors: {},
      };
    }

    /*
     * Jangan membedakan pesan antara ID tidak
     * ditemukan dan password salah agar sistem
     * tidak membocorkan daftar ID pengguna.
     */
    if (!profile) {
      return invalidCredentialState();
    }

    const {
      data: authUserData,
      error: authUserLookupError,
    } =
      await adminSupabase.auth.admin.getUserById(
        profile.id,
      );

    if (
      authUserLookupError ||
      !authUserData.user
    ) {
      console.error(
        "Auth user untuk login ID tidak ditemukan:",
        {
          loginId,
          profileId: profile.id,
          error:
            authUserLookupError?.message ??
            "User tidak tersedia.",
        },
      );

      return invalidCredentialState();
    }

    const resolvedEmail =
      authUserData.user.email
        ?.trim()
        .toLowerCase();

    if (!resolvedEmail) {
      console.error(
        "Auth user tidak mempunyai email:",
        {
          loginId,
          profileId: profile.id,
        },
      );

      return invalidCredentialState();
    }

    authEmail = resolvedEmail;
  } catch (error) {
    console.error(
      "Supabase Admin Client gagal digunakan saat login:",
      error,
    );

    return {
      status: "error",

      message:
        "Layanan login belum dapat digunakan. Periksa konfigurasi server.",

      fieldErrors: {},
    };
  }

  /*
   * Client biasa tetap digunakan agar session
   * hasil login tersimpan ke cookie aplikasi.
   */
  const supabase =
    await createClient();

  const { error: loginError } =
    await supabase.auth.signInWithPassword({
      email: authEmail,
      password,
    });

  if (loginError) {
    return invalidCredentialState();
  }

  let accessContext;

  try {
    accessContext =
      await getAccessContextWithClient(
        supabase,
      );
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

  if (
    accessContext.roles.length === 0
  ) {
    await supabase.auth.signOut();

    return {
      status: "error",

      message:
        "Akun belum mempunyai role aplikasi.",

      fieldErrors: {},
    };
  }

  const cookieStore =
    await cookies();

  let destination =
    "/select-role";

  if (
    accessContext.roles.length === 1
  ) {
    const assignedRole =
      accessContext.roles[0].code;

    cookieStore.set(
      ACTIVE_ROLE_COOKIE_NAME,
      assignedRole,
      {
        httpOnly: true,
        sameSite: "lax",

        secure:
          process.env.NODE_ENV ===
          "production",

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

  revalidatePath(
    "/",
    "layout",
  );

  redirect(destination);
}