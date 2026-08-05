type StudentFormFieldErrorProps = {
  errors?: string[];
};

export function StudentFormFieldError({
  errors,
}: StudentFormFieldErrorProps) {
  if (!errors || errors.length === 0) {
    return null;
  }

  return (
    <div className="mt-2 space-y-1">
      {errors.map((errorMessage) => (
        <p
          key={errorMessage}
          className="text-sm text-red-600"
        >
          {errorMessage}
        </p>
      ))}
    </div>
  );
}