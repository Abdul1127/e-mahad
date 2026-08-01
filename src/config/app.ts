export const appConfig = {
  name: "E-Ma'had",
  shortName: "E-Ma'had",
  description:
    "Sistem informasi terpusat untuk pengelolaan, pemantauan, dan pelaporan perkembangan santri.",
  locale: "id-ID",
  timezone: "Asia/Makassar",
  defaultRoute: "/",
} as const;

export type AppConfig = typeof appConfig;