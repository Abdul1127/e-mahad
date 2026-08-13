import "server-only";

import {
  headers,
} from "next/headers";

type GetServerActionReturnToOptions = {
  fallbackHref:
    string;

  expectedPath:
    string;
};

function normalizePath(
  value: string,
): string {
  if (
    value.length > 1 &&
    value.endsWith("/")
  ) {
    return value.slice(
      0,
      -1,
    );
  }

  return value;
}

function getSafeInternalReturnTo({
  candidate,
  fallbackHref,
  expectedPath,
}: {
  candidate:
    string | null;

  fallbackHref:
    string;

  expectedPath:
    string;
}): string {
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

    /*
     * =====================================================
     * INTERNAL URL ONLY
     * =====================================================
     *
     * Mencegah returnTo diarahkan ke domain eksternal.
     */

    if (
      candidateUrl.origin !==
      baseUrl.origin
    ) {
      return fallbackHref;
    }

    /*
     * =====================================================
     * EXACT DETAIL PATH ONLY
     * =====================================================
     *
     * Server Action pembayaran hanya boleh kembali
     * ke detail tagihan yang sedang diproses.
     *
     * Query string tetap dipertahankan karena di dalamnya
     * terdapat returnTo menuju daftar sebelumnya.
     */

    if (
      normalizePath(
        candidateUrl.pathname,
      ) !==
      normalizePath(
        expectedPath,
      )
    ) {
      return fallbackHref;
    }

    return `${candidateUrl.pathname}${candidateUrl.search}${candidateUrl.hash}`;
  } catch {
    return fallbackHref;
  }
}

export async function getServerActionReturnTo({
  fallbackHref,
  expectedPath,
}: GetServerActionReturnToOptions): Promise<string> {
  const requestHeaders =
    await headers();

  const referer =
    requestHeaders.get(
      "referer",
    );

  if (!referer) {
    return fallbackHref;
  }

  try {
    const refererUrl =
      new URL(
        referer,
      );

    const returnTo =
      refererUrl.searchParams.get(
        "returnTo",
      );

    return getSafeInternalReturnTo({
      candidate:
        returnTo,

      fallbackHref,

      expectedPath,
    });
  } catch {
    return fallbackHref;
  }
}