"use server";

import {
  redirect,
} from "next/navigation";

import {
  requireAccessContext,
} from "@/lib/auth/guards";

import {
  createClient,
} from "@/lib/supabase/server";

import {
  changeOwnPasswordSchema,
} from "../schemas/change-own-password-schema";

import type {
  ChangeOwnPasswordActionState,
} from "../types/change-own-password-action-state";


function createErrorState(
  message: string,
  fieldErrors:
    ChangeOwnPasswordActionState["fieldErrors"] =
      {},
): ChangeOwnPasswordActionState {
  return {
    status:
      "error",

    message,

    fieldErrors,
  };
}


function mapPasswordUpdateError(
  code:
    string | undefined,

  message:
    string,
): string {
  const normalized =
    `${code ?? ""} ${message}`
      .toLowerCase();

  if (
    normalized.includes(
      "same_password",
    ) ||
    normalized.includes(
      "same password",
    )
  ) {
    return (
      "Password baru harus berbeda " +
      "dari password sebelumnya."
    );
  }

  if (
    normalized.includes(
      "weak_password",
    ) ||
    normalized.includes(
      "weak password",
    )
  ) {
    return (
      "Password baru belum memenuhi " +
      "ketentuan keamanan. Gunakan " +
      "password yang lebih kuat."
    );
  }

  if (
    normalized.includes(
      "reauthentication",
    )
  ) {
    return (
      "Sesi perlu diverifikasi kembali. " +
      "Silakan keluar, login kembali, " +
      "lalu coba mengganti password."
    );
  }

  return (
    "Password belum dapat diubah. " +
    "Silakan coba kembali."
  );
}


export async function changeOwnPassword(
  _previousState:
    ChangeOwnPasswordActionState,

  formData:
    FormData,
): Promise<ChangeOwnPasswordActionState> {
  /*
   * =======================================================
   * 01. AUTHENTICATION
   * =======================================================
   *
   * Tidak dibatasi role tertentu.
   *
   * Semua user E-Ma'had yang aktif dan mempunyai
   * akses aplikasi boleh mengganti password miliknya
   * sendiri.
   */
  const context =
    await requireAccessContext();


  /*
   * =======================================================
   * 02. VALIDATION
   * =======================================================
   */

  const validationResult =
    changeOwnPasswordSchema.safeParse({
      current_password:
        String(
          formData.get(
            "current_password",
          ) ?? "",
        ),

      password:
        String(
          formData.get(
            "password",
          ) ?? "",
        ),

      password_confirmation:
        String(
          formData.get(
            "password_confirmation",
          ) ?? "",
        ),
    });


  if (
    !validationResult.success
  ) {
    return createErrorState(
      "Periksa kembali data password.",
      validationResult.error
        .flatten()
        .fieldErrors,
    );
  }


  const {
    current_password:
      currentPassword,

    password:
      newPassword,
  } =
    validationResult.data;


  /*
   * =======================================================
   * 03. SUPABASE CLIENT
   * =======================================================
   */

  let supabase;

  try {
    supabase =
      await createClient();
  } catch (error) {
    console.error(
      "Supabase client gagal dibuat saat perubahan password:",
      error,
    );

    return createErrorState(
      "Layanan perubahan password sedang tidak tersedia.",
    );
  }


  /*
   * =======================================================
   * 04. CURRENT AUTH USER
   * =======================================================
   */

  const {
    data: userData,
    error: userError,
  } =
    await supabase.auth.getUser();


  if (
    userError ||
    !userData.user
  ) {
    console.error(
      "Gagal membaca user Auth saat perubahan password:",
      userError,
    );

    return createErrorState(
      "Sesi login tidak dapat diverifikasi. Silakan login kembali.",
    );
  }


  const authUser =
    userData.user;


  /*
   * Profile aplikasi dan Auth user harus menunjuk
   * ke UUID yang sama.
   */
  if (
    authUser.id !==
    context.userId
  ) {
    console.error(
      "Auth user tidak sesuai dengan access context:",
      {
        authUserId:
          authUser.id,

        contextUserId:
          context.userId,
      },
    );

    return createErrorState(
      "Sesi akun tidak valid. Silakan keluar dan login kembali.",
    );
  }


  const internalEmail =
    authUser.email
      ?.trim()
      .toLowerCase();


  if (
    !internalEmail
  ) {
    console.error(
      "Auth user tidak mempunyai internal email:",
      {
        userId:
          authUser.id,
      },
    );

    return createErrorState(
      "Identitas akun tidak dapat diverifikasi.",
    );
  }


  /*
   * =======================================================
   * 05. VERIFY CURRENT PASSWORD
   * =======================================================
   *
   * User E-Ma'had login menggunakan ID Pengguna,
   * tetapi Supabase Auth di belakang layar memakai
   * internal auth email.
   *
   * Internal email tidak ditampilkan kepada user.
   *
   * Kita sign-in ulang dengan password saat ini agar
   * perubahan password hanya dapat dilakukan oleh
   * orang yang mengetahui password akun tersebut.
   */

  const {
    data: verificationData,
    error: verificationError,
  } =
    await supabase.auth
      .signInWithPassword({
        email:
          internalEmail,

        password:
          currentPassword,
      });


  if (
    verificationError ||
    !verificationData.user
  ) {
    const errorCode =
      verificationError
        ?.code
        ?.toLowerCase();

    const errorMessage =
      verificationError
        ?.message
        ?.toLowerCase() ??
      "";


    if (
      errorCode ===
        "invalid_credentials" ||
      errorMessage.includes(
        "invalid login credentials",
      )
    ) {
      return createErrorState(
        "Password saat ini tidak sesuai.",
        {
          current_password: [
            "Password saat ini tidak sesuai.",
          ],
        },
      );
    }


    console.error(
      "Verifikasi password saat ini gagal:",
      verificationError,
    );

    return createErrorState(
      "Password saat ini belum dapat diverifikasi. Silakan coba kembali.",
    );
  }


  if (
    verificationData.user.id !==
    context.userId
  ) {
    console.error(
      "User hasil verifikasi password tidak sesuai:",
      {
        verifiedUserId:
          verificationData.user.id,

        contextUserId:
          context.userId,
      },
    );

    return createErrorState(
      "Verifikasi akun tidak valid. Silakan login kembali.",
    );
  }


  /*
   * =======================================================
   * 06. UPDATE OWN PASSWORD
   * =======================================================
   *
   * Penting:
   *
   * Kita TIDAK menggunakan createAdminClient().
   *
   * Dengan demikian operasi ini dilakukan sebagai
   * user yang sedang login, bukan sebagai service role.
   */

  const {
    error: updateError,
  } =
    await supabase.auth
      .updateUser({
        password:
          newPassword,

        current_password:
          currentPassword,
      });


  if (
    updateError
  ) {
    console.error(
      "Gagal mengubah password sendiri:",
      {
        userId:
          context.userId,

        code:
          updateError.code,

        message:
          updateError.message,
      },
    );

    return createErrorState(
      mapPasswordUpdateError(
        updateError.code,
        updateError.message,
      ),
    );
  }


  /*
   * =======================================================
   * 07. SUCCESS
   * =======================================================
   *
   * User tetap login.
   *
   * Password baru digunakan pada proses login
   * berikutnya.
   */

  redirect(
    "/akun/password?changed=1",
  );
}