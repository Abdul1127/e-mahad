import { NextResponse } from "next/server";

import { appConfig } from "@/config/app";
import { env } from "@/config/env";

export const dynamic = "force-dynamic";

export async function GET() {
  const supabaseConfigured =
    Boolean(env.supabaseUrl.trim()) &&
    Boolean(env.supabaseAnonKey.trim());

  return NextResponse.json(
    {
      success: true,
      message: `${appConfig.name} API berjalan dengan baik.`,
      data: {
        application: appConfig.name,
        environment: process.env.NODE_ENV,
        supabaseConfigured,
        timestamp: new Date().toISOString(),
      },
    },
    {
      status: 200,
      headers: {
        "Cache-Control": "no-store",
      },
    },
  );
}