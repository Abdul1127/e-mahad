import { createServerClient } from "@supabase/ssr";
import {
  NextResponse,
  type NextRequest,
} from "next/server";

import { env } from "@/config/env";

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
      pathname.startsWith(`${prefix}/`),
  );
}

function copyResponseCookies(
  source: NextResponse,
  target: NextResponse,
): NextResponse {
  source.cookies.getAll().forEach((cookie) => {
    target.cookies.set(cookie);
  });

  return target;
}

export async function updateSession(
  request: NextRequest,
): Promise<NextResponse> {
  let response = NextResponse.next({
    request,
  });

  const supabase = createServerClient(
    env.supabaseUrl,
    env.supabaseAnonKey,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll();
        },

        setAll(cookiesToSet) {
          cookiesToSet.forEach(
            ({ name, value }) => {
              request.cookies.set(name, value);
            },
          );

          response = NextResponse.next({
            request,
          });

          cookiesToSet.forEach(
            ({ name, value, options }) => {
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
  } = await supabase.auth.getClaims();

  const isAuthenticated =
    typeof claimsData?.claims?.sub === "string";

  const pathname = request.nextUrl.pathname;

  if (
    isProtectedPath(pathname) &&
    !isAuthenticated
  ) {
    const loginUrl =
      request.nextUrl.clone();

    loginUrl.pathname = "/login";
    loginUrl.searchParams.set(
      "next",
      pathname,
    );

    return copyResponseCookies(
      response,
      NextResponse.redirect(loginUrl),
    );
  }

  if (
    pathname === "/login" &&
    isAuthenticated
  ) {
    const dashboardUrl =
      request.nextUrl.clone();

    dashboardUrl.pathname = "/dashboard";
    dashboardUrl.search = "";

    return copyResponseCookies(
      response,
      NextResponse.redirect(dashboardUrl),
    );
  }

  return response;
}