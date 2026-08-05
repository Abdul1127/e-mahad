type StudentAvatarProps = {
  fullName: string;
  gender: "male" | "female";
  size?: "small" | "medium";
};

function getInitials(
  fullName: string,
): string {
  const words = fullName
    .trim()
    .split(/\s+/)
    .filter(Boolean);

  if (words.length === 0) {
    return "S";
  }

  return words
    .slice(0, 2)
    .map((word) =>
      word.charAt(0).toUpperCase(),
    )
    .join("");
}

export function StudentAvatar({
  fullName,
  gender,
  size = "medium",
}: StudentAvatarProps) {
  const sizeClassName =
    size === "small"
      ? "size-9 text-xs"
      : "size-11 text-sm";

  const genderClassName =
    gender === "male"
      ? "bg-sky-100 text-sky-700"
      : "bg-rose-100 text-rose-700";

  return (
    <div
      aria-hidden="true"
      className={`grid shrink-0 place-items-center rounded-2xl font-bold ${sizeClassName} ${genderClassName}`}
    >
      {getInitials(fullName)}
    </div>
  );
}