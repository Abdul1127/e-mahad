"use client";

import type {
  ComponentProps,
} from "react";

import Link from "next/link";

import {
  usePathname,
  useSearchParams,
} from "next/navigation";

type BaseLinkProps = Omit<
  ComponentProps<typeof Link>,
  "href"
>;

type PreserveStateLinkProps =
  BaseLinkProps & {
    href: string;
  };

type ReturnLinkProps =
  BaseLinkProps & {
    fallbackHref: string;
    allowedPrefixes?: string[];
  };

type CarryReturnToLinkProps =
  BaseLinkProps & {
    href: string;
  };

/**
 * =========================================================
 * INTERNAL URL SAFETY
 * =========================================================
 *
 * Memastikan returnTo hanya menuju URL internal E-Ma'had.
 *
 * Contoh valid:
 * /kepala-mahad/tahfiz?page=4
 *
 * Contoh ditolak:
 * https://website-lain.com
 * //website-lain.com
 */
function getSafeInternalPath(
  candidate: string | null,
  fallbackHref: string,
  allowedPrefixes?: string[],
): string {
  if (!candidate) {
    return fallbackHref;
  }

  try {
    const baseUrl =
      new URL(
        "https://e-mahad.local",
      );

    const candidateUrl =
      new URL(
        candidate,
        baseUrl,
      );

    /**
     * URL eksternal ditolak.
     */
    if (
      candidateUrl.origin !==
      baseUrl.origin
    ) {
      return fallbackHref;
    }

    /**
     * Optional whitelist berdasarkan
     * prefix route.
     */
    if (
      allowedPrefixes &&
      allowedPrefixes.length >
        0
    ) {
      const allowed =
        allowedPrefixes.some(
          (prefix) =>
            candidateUrl.pathname ===
              prefix ||
            candidateUrl.pathname.startsWith(
              `${prefix}/`,
            ),
        );

      if (!allowed) {
        return fallbackHref;
      }
    }

    return (
      `${candidateUrl.pathname}` +
      `${candidateUrl.search}` +
      `${candidateUrl.hash}`
    );
  } catch {
    return fallbackHref;
  }
}

/**
 * =========================================================
 * APPEND RETURN TO
 * =========================================================
 *
 * Menambahkan:
 *
 * ?returnTo=/halaman-asal?page=4...
 *
 * ke target href.
 */
function appendReturnTo(
  targetHref: string,
  returnTo: string,
): string {
  try {
    const baseUrl =
      new URL(
        "https://e-mahad.local",
      );

    const targetUrl =
      new URL(
        targetHref,
        baseUrl,
      );

    /**
     * Jangan memodifikasi external URL.
     */
    if (
      targetUrl.origin !==
      baseUrl.origin
    ) {
      return targetHref;
    }

    targetUrl.searchParams.set(
      "returnTo",
      returnTo,
    );

    return (
      `${targetUrl.pathname}` +
      `${targetUrl.search}` +
      `${targetUrl.hash}`
    );
  } catch {
    return targetHref;
  }
}

/**
 * =========================================================
 * CURRENT INTERNAL PATH
 * =========================================================
 *
 * Menghasilkan:
 *
 * /kepala-mahad/tahfiz
 * /kepala-mahad/tahfiz?page=4
 * /kepala-mahad/tahfiz?page=4&group=...
 */
function buildCurrentPath(
  pathname: string,
  searchParams: URLSearchParams,
): string {
  const query =
    searchParams.toString();

  if (!query) {
    return pathname;
  }

  return `${pathname}?${query}`;
}

/**
 * =========================================================
 * PRESERVE STATE LINK
 * =========================================================
 *
 * Digunakan dari LIST -> DETAIL.
 *
 * Contoh:
 *
 * Sekarang:
 * /kepala-mahad/tahfiz?page=4&group=ABC
 *
 * Klik:
 * /kepala-mahad/tahfiz/{studentId}
 *
 * Hasil:
 * /kepala-mahad/tahfiz/{studentId}
 * ?returnTo=%2Fkepala-mahad%2Ftahfiz%3Fpage%3D4...
 */
export function PreserveStateLink({
  href,
  ...props
}: PreserveStateLinkProps) {
  const pathname =
    usePathname();

  const searchParams =
    useSearchParams();

  const currentPath =
    buildCurrentPath(
      pathname,
      searchParams,
    );

  const resolvedHref =
    appendReturnTo(
      href,
      currentPath,
    );

  return (
    <Link
      {...props}
      href={resolvedHref}
    />
  );
}

/**
 * =========================================================
 * RETURN LINK
 * =========================================================
 *
 * Digunakan dari DETAIL -> LIST.
 *
 * Membaca returnTo dari URL.
 *
 * Kalau returnTo hilang / tidak valid,
 * fallbackHref akan digunakan.
 */
export function ReturnLink({
  fallbackHref,
  allowedPrefixes,
  ...props
}: ReturnLinkProps) {
  const searchParams =
    useSearchParams();

  const resolvedHref =
    getSafeInternalPath(
      searchParams.get(
        "returnTo",
      ),
      fallbackHref,
      allowedPrefixes,
    );

  return (
    <Link
      {...props}
      href={resolvedHref}
    />
  );
}

/**
 * =========================================================
 * CARRY RETURN TO LINK
 * =========================================================
 *
 * Digunakan ketika berada di DETAIL
 * lalu berpindah ke halaman lain yang
 * masih merupakan bagian dari detail.
 *
 * Contoh:
 *
 * Detail riwayat:
 *
 * /tahfiz/{studentId}
 * ?page=1
 * &returnTo=/tahfiz?page=4
 *
 * Klik halaman riwayat berikutnya:
 *
 * /tahfiz/{studentId}
 * ?page=2
 * &returnTo=/tahfiz?page=4
 *
 * Dengan demikian tombol "Kembali"
 * tetap tahu posisi list asal.
 */
export function CarryReturnToLink({
  href,
  ...props
}: CarryReturnToLinkProps) {
  const searchParams =
    useSearchParams();

  const rawReturnTo =
    searchParams.get(
      "returnTo",
    );

  const safeReturnTo =
    getSafeInternalPath(
      rawReturnTo,
      "",
    );

  const resolvedHref =
    safeReturnTo
      ? appendReturnTo(
          href,
          safeReturnTo,
        )
      : href;

  return (
    <Link
      {...props}
      href={resolvedHref}
    />
  );
}