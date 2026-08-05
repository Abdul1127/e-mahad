export type StudentFormFieldErrors = {
  legacyStudentId?: string[];
  nis?: string[];
  fullName?: string[];
  gender?: string[];
  status?: string[];
  classId?: string[];
  careGroupId?: string[];
  tahfizGroupId?: string[];
};

export type StudentFormActionState = {
  status: "idle" | "error";
  message: string;
  fieldErrors: StudentFormFieldErrors;
};

export const initialStudentFormActionState: StudentFormActionState =
  {
    status: "idle",
    message: "",
    fieldErrors: {},
  };