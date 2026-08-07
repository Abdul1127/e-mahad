import { z } from "zod";

export const staffRoleUpdateSchema =
  z.object({
    role_codes: z
      .array(
        z.string().trim().min(1),
      )
      .min(
        1,
        "Pilih minimal satu role staf.",
      ),
  });