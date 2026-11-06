export const USER_ROLES = ['customer', 'owner', 'technician', 'staff'] as const;
export type UserRole = typeof USER_ROLES[number];
