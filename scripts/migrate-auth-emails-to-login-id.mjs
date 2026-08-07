import {
  mkdir,
  writeFile,
} from "node:fs/promises";

import { resolve } from "node:path";

import { createClient } from "@supabase/supabase-js";

const INTERNAL_EMAIL_DOMAIN =
  "login.emahad.id";

const LOGIN_ID_PATTERN =
  /^[A-Z0-9]+(?:-[A-Z0-9]+)*$/;

const shouldApply =
  process.argv.includes("--apply");

function requireEnvironment(
  name,
  value,
) {
  if (!value) {
    throw new Error(
      `Environment variable ${name} belum tersedia.`,
    );
  }

  return value;
}

function createInternalAuthEmail(
  loginId,
) {
  return `${loginId.toLowerCase()}@${INTERNAL_EMAIL_DOMAIN}`;
}

function createTimestamp() {
  return new Date()
    .toISOString()
    .replaceAll(":", "-")
    .replaceAll(".", "-");
}

function printMigrationTable(
  records,
) {
  console.table(
    records.map((record) => ({
      login_id: record.loginId,
      nama: record.fullName,
      email_sekarang:
        record.previousEmail,
      email_baru:
        record.targetEmail,
      status:
        record.previousEmail ===
        record.targetEmail
          ? "Sudah sesuai"
          : "Perlu migrasi",
    })),
  );
}

async function main() {
  const supabaseUrl =
    requireEnvironment(
      "NEXT_PUBLIC_SUPABASE_URL",
      process.env
        .NEXT_PUBLIC_SUPABASE_URL,
    );

  const supabaseSecretKey =
    process.env.SUPABASE_SECRET_KEY ??
    process.env
      .SUPABASE_SERVICE_ROLE_KEY;

  requireEnvironment(
    "SUPABASE_SECRET_KEY atau SUPABASE_SERVICE_ROLE_KEY",
    supabaseSecretKey,
  );

  const supabase = createClient(
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

  console.log("");
  console.log(
    "E-Ma'had — Migrasi Email Auth ke Login ID",
  );
  console.log(
    "========================================",
  );
  console.log(
    `Mode: ${
      shouldApply
        ? "APPLY"
        : "DRY RUN"
    }`,
  );
  console.log("");

  const {
    data: profiles,
    error: profilesError,
  } = await supabase
    .from("profiles")
    .select(
      "id, full_name, login_id, is_active",
    )
    .order("login_id", {
      ascending: true,
    });

  if (profilesError) {
    throw new Error(
      `Gagal membaca profiles: ${profilesError.message}`,
    );
  }

  if (
    !profiles ||
    profiles.length === 0
  ) {
    throw new Error(
      "Tidak ada profile yang dapat dimigrasikan.",
    );
  }

  const profilesWithoutLoginId =
    profiles.filter(
      (profile) =>
        !profile.login_id,
    );

  if (
    profilesWithoutLoginId.length >
    0
  ) {
    console.table(
      profilesWithoutLoginId.map(
        (profile) => ({
          profile_id: profile.id,
          nama: profile.full_name,
        }),
      ),
    );

    throw new Error(
      "Masih ada profile tanpa login_id. Migrasi dihentikan.",
    );
  }

  const migrationRecords = [];

  for (const profile of profiles) {
    const loginId =
      profile.login_id.trim();

    if (
      !LOGIN_ID_PATTERN.test(
        loginId,
      )
    ) {
      throw new Error(
        `Format login_id ${loginId} tidak valid.`,
      );
    }

    const {
      data: authUserData,
      error: authUserError,
    } =
      await supabase.auth.admin
        .getUserById(profile.id);

    if (
      authUserError ||
      !authUserData.user
    ) {
      throw new Error(
        [
          "Auth user tidak ditemukan",
          `untuk profile ${profile.id}`,
          `(${profile.full_name}).`,
          authUserError?.message ?? "",
        ].join(" "),
      );
    }

    const previousEmail =
      authUserData.user.email
        ?.trim()
        .toLowerCase();

    if (!previousEmail) {
      throw new Error(
        `Auth user ${profile.id} tidak mempunyai email.`,
      );
    }

    migrationRecords.push({
      profileId: profile.id,
      fullName: profile.full_name,
      loginId,
      isActive: profile.is_active,
      previousEmail,
      targetEmail:
        createInternalAuthEmail(
          loginId,
        ),
      previousUserMetadata:
        authUserData.user
          .user_metadata ?? {},
    });
  }

  const targetEmailMap =
    new Map();

  for (
    const record of
    migrationRecords
  ) {
    const existingRecord =
      targetEmailMap.get(
        record.targetEmail,
      );

    if (existingRecord) {
      throw new Error(
        [
          "Email internal duplikat:",
          record.targetEmail,
          `digunakan oleh ${existingRecord.loginId}`,
          `dan ${record.loginId}.`,
        ].join(" "),
      );
    }

    targetEmailMap.set(
      record.targetEmail,
      record,
    );
  }

  printMigrationTable(
    migrationRecords,
  );

  const recordsToMigrate =
    migrationRecords.filter(
      (record) =>
        record.previousEmail !==
        record.targetEmail,
    );

  console.log("");
  console.log(
    `Total profile       : ${migrationRecords.length}`,
  );
  console.log(
    `Perlu dimigrasikan  : ${recordsToMigrate.length}`,
  );
  console.log(
    `Sudah sesuai        : ${
      migrationRecords.length -
      recordsToMigrate.length
    }`,
  );
  console.log("");

  if (!shouldApply) {
    console.log(
      "DRY RUN selesai. Tidak ada akun yang diubah.",
    );
    console.log("");
    console.log(
      "Jalankan kembali dengan --apply setelah hasil simulasi diperiksa.",
    );

    return;
  }

  if (
    recordsToMigrate.length === 0
  ) {
    console.log(
      "Semua email Auth sudah sesuai. Tidak ada perubahan.",
    );

    return;
  }

  const backupDirectory =
    resolve(
      process.cwd(),
      ".local-backups",
    );

  await mkdir(
    backupDirectory,
    {
      recursive: true,
    },
  );

  const backupPath =
    resolve(
      backupDirectory,
      `auth-email-migration-${createTimestamp()}.json`,
    );

  await writeFile(
    backupPath,
    JSON.stringify(
      {
        generated_at:
          new Date().toISOString(),

        project:
          "E-Ma'had",

        records:
          migrationRecords.map(
            (record) => ({
              profile_id:
                record.profileId,

              full_name:
                record.fullName,

              login_id:
                record.loginId,

              previous_email:
                record.previousEmail,

              target_email:
                record.targetEmail,
            }),
          ),
      },
      null,
      2,
    ),
    "utf8",
  );

  console.log(
    `Backup lokal dibuat: ${backupPath}`,
  );
  console.log("");

  const successfullyMigrated =
    [];

  try {
    for (
      const record of
      recordsToMigrate
    ) {
      console.log(
        `Memigrasikan ${record.loginId}...`,
      );

      const {
        data: updatedUserData,
        error: updateError,
      } =
        await supabase.auth.admin
          .updateUserById(
            record.profileId,
            {
              email:
                record.targetEmail,

              email_confirm: true,

              user_metadata: {
                ...record
                  .previousUserMetadata,

                login_id:
                  record.loginId,

                account_identifier:
                  record.loginId,
              },
            },
          );

      if (
        updateError ||
        !updatedUserData.user
      ) {
        throw new Error(
          [
            `Gagal memigrasikan ${record.loginId}:`,
            updateError?.message ??
              "Supabase tidak mengembalikan user.",
          ].join(" "),
        );
      }

      const verifiedEmail =
        updatedUserData.user.email
          ?.trim()
          .toLowerCase();

      if (
        verifiedEmail !==
        record.targetEmail
      ) {
        throw new Error(
          [
            `Verifikasi email ${record.loginId} gagal.`,
            `Diharapkan ${record.targetEmail},`,
            `diterima ${verifiedEmail ?? "-"}.`,
          ].join(" "),
        );
      }

      successfullyMigrated.push(
        record,
      );

      console.log(
        `Berhasil: ${record.targetEmail}`,
      );
    }
  } catch (migrationError) {
    console.error("");
    console.error(
      "Migrasi berhenti karena error:",
      migrationError,
    );

    if (
      successfullyMigrated.length >
      0
    ) {
      console.error("");
      console.error(
        "Mencoba rollback akun yang sudah berubah...",
      );

      for (
        const record of
        [...successfullyMigrated].reverse()
      ) {
        const {
          error: rollbackError,
        } =
          await supabase.auth.admin
            .updateUserById(
              record.profileId,
              {
                email:
                  record.previousEmail,

                email_confirm: true,

                user_metadata: {
                  ...record
                    .previousUserMetadata,
                },
              },
            );

        if (rollbackError) {
          console.error(
            [
              `ROLLBACK GAGAL untuk ${record.loginId}:`,
              rollbackError.message,
            ].join(" "),
          );
        } else {
          console.error(
            `Rollback berhasil: ${record.loginId}`,
          );
        }
      }
    }

    throw migrationError;
  }

  console.log("");
  console.log(
    "Memverifikasi hasil akhir...",
  );

  const finalResults = [];

  for (
    const record of
    migrationRecords
  ) {
    const {
      data: finalUserData,
      error: finalUserError,
    } =
      await supabase.auth.admin
        .getUserById(
          record.profileId,
        );

    if (
      finalUserError ||
      !finalUserData.user
    ) {
      throw new Error(
        `Verifikasi akhir gagal untuk ${record.loginId}.`,
      );
    }

    finalResults.push({
      login_id:
        record.loginId,

      nama:
        record.fullName,

      email_auth:
        finalUserData.user.email,

      sesuai:
        finalUserData.user.email
          ?.toLowerCase() ===
        record.targetEmail,
    });
  }

  console.table(
    finalResults,
  );

  const invalidResults =
    finalResults.filter(
      (result) =>
        !result.sesuai,
    );

  if (
    invalidResults.length > 0
  ) {
    throw new Error(
      "Masih ada email Auth yang belum sesuai.",
    );
  }

  console.log("");
  console.log(
    "MIGRASI BERHASIL.",
  );
  console.log(
    "Semua akun sekarang menggunakan email internal berdasarkan login ID.",
  );
}

main().catch((error) => {
  console.error("");
  console.error(
    error instanceof Error
      ? error.message
      : error,
  );

  process.exitCode = 1;
});