import type { RoleCode } from "@/config/roles";

export type UserRole = {
  code: RoleCode;
  name: string;
};

export type AccessContext = {
  userId: string;
  email: string | null;
  fullName: string;
  isActive: boolean;
  staffId: string | null;
  guardianId: string | null;
  roles: UserRole[];
};