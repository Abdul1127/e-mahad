export type AppIconName =
  | "dashboard"
  | "students"
  | "staff"
  | "groups"
  | "tahfiz"
  | "journal"
  | "finance"
  | "clinic"
  | "settings"
  | "home"
  | "menu"
  | "close"
  | "switch"
  | "logout"
  | "shield"
  | "chevron-right";

type AppIconProps = {
  name: AppIconName;
  className?: string;
  strokeWidth?: number;
};

function IconPaths({
  name,
}: {
  name: AppIconName;
}) {
  switch (name) {
    case "dashboard":
      return (
        <>
          <rect x="3" y="3" width="7" height="7" rx="1" />
          <rect x="14" y="3" width="7" height="4" rx="1" />
          <rect x="14" y="11" width="7" height="10" rx="1" />
          <rect x="3" y="14" width="7" height="7" rx="1" />
        </>
      );

    case "students":
      return (
        <>
          <path d="m3 10 9-5 9 5-9 5-9-5Z" />
          <path d="M7 12.5V17c3 2.5 7 2.5 10 0v-4.5" />
          <path d="M21 10v6" />
        </>
      );

    case "staff":
      return (
        <>
          <circle cx="9" cy="8" r="4" />
          <path d="M2.5 21a6.5 6.5 0 0 1 13 0" />
          <path d="M17 8.5a3.5 3.5 0 0 1 0 7" />
          <path d="M19 17a5 5 0 0 1 2.5 4" />
        </>
      );

    case "groups":
      return (
        <>
          <circle cx="12" cy="7" r="3" />
          <circle cx="5" cy="10" r="2" />
          <circle cx="19" cy="10" r="2" />
          <path d="M7 21a5 5 0 0 1 10 0" />
          <path d="M1.5 20a3.5 3.5 0 0 1 5.5-2.9" />
          <path d="M17 17.1A3.5 3.5 0 0 1 22.5 20" />
        </>
      );

    case "tahfiz":
      return (
        <>
          <path d="M4 5.5A3.5 3.5 0 0 1 7.5 2H12v18H7.5A3.5 3.5 0 0 0 4 23.5Z" />
          <path d="M20 5.5A3.5 3.5 0 0 0 16.5 2H12v18h4.5a3.5 3.5 0 0 1 3.5 3.5Z" />
        </>
      );

    case "journal":
      return (
        <>
          <path d="M5 3h11a3 3 0 0 1 3 3v15H7a3 3 0 0 1-3-3V4a1 1 0 0 1 1-1Z" />
          <path d="M7 21a3 3 0 0 1 0-6h12" />
          <path d="M8 7h7" />
          <path d="M8 11h5" />
        </>
      );

    case "finance":
      return (
        <>
          <rect x="3" y="5" width="18" height="14" rx="2" />
          <path d="M3 9h18" />
          <path d="M7 15h3" />
          <path d="M16 13.5v3" />
        </>
      );

    case "clinic":
      return (
        <>
          <path d="M12 21s8-4.5 8-11a4.5 4.5 0 0 0-8-2.8A4.5 4.5 0 0 0 4 10c0 6.5 8 11 8 11Z" />
          <path d="M9 12h6" />
          <path d="M12 9v6" />
        </>
      );

    case "settings":
      return (
        <>
          <circle cx="12" cy="12" r="3" />
          <path d="M19.4 15a1.7 1.7 0 0 0 .3 1.9l.1.1-2.8 2.8-.1-.1a1.7 1.7 0 0 0-1.9-.3 1.7 1.7 0 0 0-1 1.6V21h-4v-.1a1.7 1.7 0 0 0-1-1.6 1.7 1.7 0 0 0-1.9.3l-.1.1L4.2 17l.1-.1a1.7 1.7 0 0 0 .3-1.9A1.7 1.7 0 0 0 3 14H3v-4h.1a1.7 1.7 0 0 0 1.6-1 1.7 1.7 0 0 0-.3-1.9L4.2 7 7 4.2l.1.1A1.7 1.7 0 0 0 9 4.6a1.7 1.7 0 0 0 1-1.6V3h4v.1a1.7 1.7 0 0 0 1 1.6 1.7 1.7 0 0 0 1.9-.3l.1-.1L19.8 7l-.1.1a1.7 1.7 0 0 0-.3 1.9 1.7 1.7 0 0 0 1.6 1h.1v4H21a1.7 1.7 0 0 0-1.6 1Z" />
        </>
      );

    case "home":
      return (
        <>
          <path d="m3 11 9-8 9 8" />
          <path d="M5 10v11h14V10" />
          <path d="M9 21v-6h6v6" />
        </>
      );

    case "menu":
      return (
        <>
          <path d="M4 7h16" />
          <path d="M4 12h16" />
          <path d="M4 17h16" />
        </>
      );

    case "close":
      return (
        <>
          <path d="m6 6 12 12" />
          <path d="M18 6 6 18" />
        </>
      );

    case "switch":
      return (
        <>
          <path d="M7 7h12l-3-3" />
          <path d="m19 7-3 3" />
          <path d="M17 17H5l3 3" />
          <path d="m5 17 3-3" />
        </>
      );

    case "logout":
      return (
        <>
          <path d="M10 4H5a2 2 0 0 0-2 2v12a2 2 0 0 0 2 2h5" />
          <path d="M14 8l4 4-4 4" />
          <path d="M18 12H8" />
        </>
      );

    case "shield":
      return (
        <>
          <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10Z" />
          <path d="m9 12 2 2 4-4" />
        </>
      );

    case "chevron-right":
      return <path d="m9 18 6-6-6-6" />;
  }
}

export function AppIcon({
  name,
  className = "size-5",
  strokeWidth = 1.8,
}: AppIconProps) {
  return (
    <svg
      aria-hidden="true"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth={strokeWidth}
      strokeLinecap="round"
      strokeLinejoin="round"
      className={className}
    >
      <IconPaths name={name} />
    </svg>
  );
}