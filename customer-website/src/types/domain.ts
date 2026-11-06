export type BookingStatus = 'requested'|'accepted'|'technician_assigned'|'on_the_way'|'inspecting'|'awaiting_approval'|'in_progress'|'quality_check'|'completed'|'cancelled';
export type UserRole = 'customer'|'owner'|'technician'|'staff';
export interface PriceBreakdown { partAmount: number; labourAmount: number; doorstepAmount: number; estimatedTotal: number; currency: 'INR'; }
