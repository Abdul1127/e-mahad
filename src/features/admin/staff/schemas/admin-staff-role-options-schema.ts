import { z } from "zod";

import { adminStaffRoleSchema } from "./admin-staff-list-schema";

export const adminStaffRoleOptionsSchema =
  z.array(
    adminStaffRoleSchema,
  );

export type AdminStaffRoleOption =
  z.infer<
    typeof adminStaffRoleOptionsSchema
  >[number];