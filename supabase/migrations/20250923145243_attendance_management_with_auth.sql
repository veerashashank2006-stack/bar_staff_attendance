-- Location: supabase/migrations/20250923145243_attendance_management_with_auth.sql
-- Schema Analysis: Fresh project - no existing tables
-- Integration Type: Complete new implementation
-- Dependencies: None - creating all new tables

-- 1. Extensions & Types
CREATE TYPE public.user_role AS ENUM ('admin', 'manager', 'employee');
CREATE TYPE public.attendance_status AS ENUM ('present', 'absent', 'late', 'half_day');
CREATE TYPE public.leave_status AS ENUM ('pending', 'approved', 'rejected');
CREATE TYPE public.leave_type AS ENUM ('sick', 'casual', 'vacation', 'maternity', 'paternity', 'emergency');

-- 2. Core Tables
-- Critical intermediary table for PostgREST compatibility
CREATE TABLE public.user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    employee_id TEXT NOT NULL UNIQUE,
    email TEXT NOT NULL UNIQUE,
    full_name TEXT NOT NULL,
    phone TEXT,
    department TEXT,
    position TEXT,
    role public.user_role DEFAULT 'employee'::public.user_role,
    is_active BOOLEAN DEFAULT true,
    profile_image_url TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Attendance records
CREATE TABLE public.attendance_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    check_in_time TIMESTAMPTZ,
    check_out_time TIMESTAMPTZ,
    status public.attendance_status DEFAULT 'present'::public.attendance_status,
    location_lat DECIMAL(10, 8),
    location_lng DECIMAL(11, 8),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Leave requests
CREATE TABLE public.leave_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    leave_type public.leave_type NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    total_days INTEGER NOT NULL,
    reason TEXT NOT NULL,
    status public.leave_status DEFAULT 'pending'::public.leave_status,
    approved_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    approved_at TIMESTAMPTZ,
    manager_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Notifications
CREATE TABLE public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT DEFAULT 'info',
    is_read BOOLEAN DEFAULT false,
    data JSONB,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 3. Essential Indexes
CREATE INDEX idx_user_profiles_employee_id ON public.user_profiles(employee_id);
CREATE INDEX idx_user_profiles_email ON public.user_profiles(email);
CREATE INDEX idx_attendance_records_user_id ON public.attendance_records(user_id);
CREATE INDEX idx_attendance_records_date ON public.attendance_records(date);
CREATE INDEX idx_attendance_records_user_date ON public.attendance_records(user_id, date);
CREATE INDEX idx_leave_requests_user_id ON public.leave_requests(user_id);
CREATE INDEX idx_leave_requests_status ON public.leave_requests(status);
CREATE INDEX idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX idx_notifications_is_read ON public.notifications(user_id, is_read);

-- 4. Functions (MUST be before RLS policies)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO public.user_profiles (id, email, full_name, employee_id, role)
    VALUES (
        NEW.id, 
        NEW.email, 
        COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
        COALESCE(NEW.raw_user_meta_data->>'employee_id', 'EMP' || EXTRACT(EPOCH FROM NOW())::INTEGER::TEXT),
        COALESCE((NEW.raw_user_meta_data->>'role')::public.user_role, 'employee'::public.user_role)
    );
    RETURN NEW;
END;
$$;

-- Update trigger for updated_at
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

-- 5. Enable RLS
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.leave_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- 6. RLS Policies using Pattern 1 & 2 (Simple, Direct)

-- Pattern 1: Core user table (user_profiles) - Simple only, no functions
CREATE POLICY "users_manage_own_user_profiles"
ON public.user_profiles
FOR ALL
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

-- Pattern 2: Simple user ownership for other tables
CREATE POLICY "users_manage_own_attendance_records"
ON public.attendance_records
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "users_manage_own_leave_requests"
ON public.leave_requests
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "users_view_own_notifications"
ON public.notifications
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- Managers can view team data using auth metadata
CREATE OR REPLACE FUNCTION public.is_manager_from_auth()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS (
    SELECT 1 FROM auth.users au
    WHERE au.id = auth.uid() 
    AND (au.raw_user_meta_data->>'role' IN ('admin', 'manager')
         OR au.raw_app_meta_data->>'role' IN ('admin', 'manager'))
)
$$;

-- Managers can view all attendance records
CREATE POLICY "managers_view_all_attendance"
ON public.attendance_records
FOR SELECT
TO authenticated
USING (public.is_manager_from_auth());

-- Managers can view all leave requests
CREATE POLICY "managers_view_all_leave_requests"
ON public.leave_requests
FOR SELECT
TO authenticated
USING (public.is_manager_from_auth());

-- 7. Triggers
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

CREATE TRIGGER handle_updated_at_user_profiles
    BEFORE UPDATE ON public.user_profiles
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER handle_updated_at_attendance_records
    BEFORE UPDATE ON public.attendance_records
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER handle_updated_at_leave_requests
    BEFORE UPDATE ON public.leave_requests
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 8. Mock Data with Complete Auth Users
DO $$
DECLARE
    admin_uuid UUID := gen_random_uuid();
    manager_uuid UUID := gen_random_uuid();
    employee1_uuid UUID := gen_random_uuid();
    employee2_uuid UUID := gen_random_uuid();
BEGIN
    -- Create complete auth.users records (required for proper authentication)
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        created_at, updated_at, raw_user_meta_data, raw_app_meta_data,
        is_sso_user, is_anonymous, confirmation_token, confirmation_sent_at,
        recovery_token, recovery_sent_at, email_change_token_new, email_change,
        email_change_sent_at, email_change_token_current, email_change_confirm_status,
        reauthentication_token, reauthentication_sent_at, phone, phone_change,
        phone_change_token, phone_change_sent_at
    ) VALUES
        (admin_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'admin@barstaff.com', crypt('admin123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Sarah Johnson", "employee_id": "EMP001", "role": "admin"}'::jsonb, 
         '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (manager_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'manager@barstaff.com', crypt('manager123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Mike Wilson", "employee_id": "EMP002", "role": "manager"}'::jsonb, 
         '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (employee1_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'employee1@barstaff.com', crypt('staff123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Alex Chen", "employee_id": "EMP003", "role": "employee"}'::jsonb, 
         '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (employee2_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'employee2@barstaff.com', crypt('staff456', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Emma Davis", "employee_id": "EMP004", "role": "employee"}'::jsonb, 
         '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null);

    -- Sample attendance records
    INSERT INTO public.attendance_records (user_id, date, check_in_time, check_out_time, status) VALUES
        (employee1_uuid, CURRENT_DATE, 
         CURRENT_DATE + INTERVAL '9 hours', 
         CURRENT_DATE + INTERVAL '17 hours', 'present'),
        (employee2_uuid, CURRENT_DATE, 
         CURRENT_DATE + INTERVAL '9 hours 15 minutes', 
         CURRENT_DATE + INTERVAL '17 hours 30 minutes', 'late'),
        (employee1_uuid, CURRENT_DATE - INTERVAL '1 day', 
         CURRENT_DATE - INTERVAL '1 day' + INTERVAL '9 hours', 
         CURRENT_DATE - INTERVAL '1 day' + INTERVAL '17 hours', 'present');

    -- Sample leave requests
    INSERT INTO public.leave_requests (user_id, leave_type, start_date, end_date, total_days, reason, status) VALUES
        (employee1_uuid, 'vacation', CURRENT_DATE + INTERVAL '7 days', 
         CURRENT_DATE + INTERVAL '9 days', 3, 'Family vacation', 'approved'),
        (employee2_uuid, 'sick', CURRENT_DATE + INTERVAL '2 days', 
         CURRENT_DATE + INTERVAL '3 days', 2, 'Medical appointment', 'pending');

    -- Sample notifications
    INSERT INTO public.notifications (user_id, title, message, type) VALUES
        (employee1_uuid, 'Leave Approved', 'Your vacation leave request has been approved.', 'success'),
        (employee2_uuid, 'Attendance Reminder', 'Please remember to check in on time.', 'warning'),
        (manager_uuid, 'New Leave Request', 'Emma Davis has submitted a new leave request.', 'info');

EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'Foreign key error: %', SQLERRM;
    WHEN unique_violation THEN
        RAISE NOTICE 'Unique constraint error: %', SQLERRM;
    WHEN OTHERS THEN
        RAISE NOTICE 'Unexpected error: %', SQLERRM;
END $$;

-- 9. Cleanup function for development
CREATE OR REPLACE FUNCTION public.cleanup_mock_data()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    mock_user_ids UUID[];
BEGIN
    -- Get mock user IDs
    SELECT ARRAY_AGG(id) INTO mock_user_ids
    FROM auth.users
    WHERE email LIKE '%@barstaff.com';

    -- Delete in dependency order
    DELETE FROM public.notifications WHERE user_id = ANY(mock_user_ids);
    DELETE FROM public.leave_requests WHERE user_id = ANY(mock_user_ids);
    DELETE FROM public.attendance_records WHERE user_id = ANY(mock_user_ids);
    DELETE FROM public.user_profiles WHERE id = ANY(mock_user_ids);
    DELETE FROM auth.users WHERE id = ANY(mock_user_ids);

    RAISE NOTICE 'Mock data cleanup completed';
EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'Foreign key constraint prevents deletion: %', SQLERRM;
    WHEN OTHERS THEN
        RAISE NOTICE 'Cleanup failed: %', SQLERRM;
END;
$$;