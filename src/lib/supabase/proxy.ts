import {
  createServerClient,
} from "@supabase/ssr";

import {
  NextResponse,
  type NextRequest,
} from "next/server";

import {
  env,
} from "@/config/env";

const protectedPrefixes = [
  "/dashboard",
  "/select-role",
  "/admin",
  "/penanggung-jawab",
  "/kepala-mahad",
  "/pengasuh",
  "/pembina-tahfiz",
  "/bendahara",
  "/wali",
];

function isProtectedPath(
  pathname: string,
): boolean {
  return protectedPrefixes.some(
    (prefix) =>
      pathname === prefix ||
      pathname.startsWith(
        `${prefix}/`,
      ),
  );
}

function copyResponseCookies(
  source: NextResponse,
  target: NextResponse,
): NextResponse {
  source.cookies
    .getAll()
    .forEach(
      (cookie) => {
        target.cookies.set(
          cookie,
        );
      },
    );

  return target;
}

/**
 * Server Actions menggunakan protocol response khusus Next.js.
 *
 * Proxy tidak boleh mengganti response Server Action dengan
 * redirect HTML biasa karena dapat menyebabkan client menerima
 * response yang tidak sesuai format Server Action.
 */
function isServerActionRequest(
  request: NextRequest,
): boolean {
  return request.headers.has(
    "next-action",
  );
}

export async function updateSession(
  request: NextRequest,
): Promise<NextResponse> {
  let response =
    NextResponse.next({
      request,
    });

  const supabase =
    createServerClient(
      env.supabaseUrl,
      env.supabaseAnonKey,
      {
        cookies: {
          getAll() {
            return request.cookies.getAll();
          },

          setAll(
            cookiesToSet,
          ) {
            cookiesToSet.forEach(
              ({
                name,
                value,
              }) => {
                request.cookies.set(
                  name,
                  value,
                );
              },
            );

            response =
              NextResponse.next({
                request,
              });

            cookiesToSet.forEach(
              ({
                name,
                value,
                options,
              }) => {
                response.cookies.set(
                  name,
                  value,
                  options,
                );
              },
            );
          },
        },
      },
    );

  const {
    data: claimsData,
  } =
    await supabase.auth.getClaims();

  const isAuthenticated =
    typeof claimsData
      ?.claims
      ?.sub ===
    "string";

  const pathname =
    request.nextUrl.pathname;

  const isServerAction =
    isServerActionRequest(
      request,
    );

  /**
   * =========================================================
   * SERVER ACTION
   * =========================================================
   *
   * Jangan melakukan navigation redirect dari Proxy terhadap
   * Server Action.
   *
   * Authentication / authorization tetap divalidasi oleh
   * Server Action dan requireRole() masing-masing.
   */
  if (isServerAction) {
    return response;
  }

  /**
   * =========================================================
   * PROTECTED PAGE
   * =========================================================
   *
   * User yang belum login diarahkan ke halaman login bersih.
   *
   * Kita sengaja tidak lagi menyimpan ?next=...
   * karena login E-Ma'had harus selalu menentukan tujuan dari
   * role akun yang BARU login.
   *
   * Ini mencegah tujuan akun sebelumnya terbawa ketika
   * pengguna berganti akun.
   */
  if (
    isProtectedPath(
      pathname,
    ) &&
    !isAuthenticated
  ) {
    const loginUrl =
      request.nextUrl.clone();

    loginUrl.pathname =
      "/login";

    loginUrl.search =
      "";

    return copyResponseCookies(
      response,
      NextResponse.redirect(
        loginUrl,
      ),
    );
  }

  /**
   * =========================================================
   * AUTHENTICATED USER ON LOGIN PAGE
   * =========================================================
   *
   * Kalau session masih aktif lalu user membuka /login secara
   * normal, arahkan ke dashboard resolver.
   *
   * Dashboard resolver kemudian menentukan dashboard berdasarkan
   * context / active role user.
   */
  if (
    pathname ===
      "/login" &&
    isAuthenticated
  ) {
    const dashboardUrl =
      request.nextUrl.clone();

    dashboardUrl.pathname =
      "/dashboard";

    dashboardUrl.search =
      "";

    return copyResponseCookies(
      response,
      NextResponse.redirect(
        dashboardUrl,
      ),
    );
  }

  return response;
}