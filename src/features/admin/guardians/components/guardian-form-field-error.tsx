type GuardianFormFieldErrorProps = {
  id: string;
  errors?: string[];
};

export function GuardianFormFieldError({
  id,
  errors,
}: GuardianFormFieldErrorProps) {
  if (!errors || errors.length === 0) {
    return null;
  }

  return (
    <div
      id={id}
      className="mt-2 space-y-1"
    >
      {errors.map((error) => (
        <p
          key={error}
          className="text-sm font-medium text-red-600"
        >
          {error}
        </p>
      ))}
    </div>
  );
}