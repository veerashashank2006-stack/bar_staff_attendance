-- Location: supabase/migrations/20250923151517_qr_attendance_for_verra_org.sql
-- Schema Analysis: New Supabase project for verra.shashank2006@gmail.com organization
-- Integration Type: Complete QR-based attendance system setup
-- Dependencies: None - creating new schema for fresh Supabase project

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

-- Attendance records with QR code integration
CREATE TABLE public.attendance_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    check_in_time TIMESTAMPTZ,
    check_out_time TIMESTAMPTZ,
    status public.attendance_status DEFAULT 'present'::public.attendance_status,
    location_lat DECIMAL(10, 8),
    location_lng DECIMAL(11, 8),
    qr_code TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- QR code configuration table for organization settings
CREATE TABLE public.qr_attendance_config (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_name TEXT NOT NULL DEFAULT 'Verra Organization',
    qr_code_prefix TEXT NOT NULL DEFAULT 'VERRA_ATT',
    location_validation_enabled BOOLEAN DEFAULT true,
    allowed_latitude DECIMAL(10, 8) DEFAULT 40.7128,
    allowed_longitude DECIMAL(11, 8) DEFAULT -74.0060,
    geofence_radius_meters INTEGER DEFAULT 100,
    work_start_time TIME DEFAULT '09:00:00',
    work_end_time TIME DEFAULT '17:00:00',
    late_threshold_minutes INTEGER DEFAULT 15,
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

-- Notifications for attendance events
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
CREATE INDEX idx_attendance_records_qr_code ON public.attendance_records(qr_code);
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
        COALESCE(NEW.raw_user_meta_data->>'employee_id', 'VER' || EXTRACT(EPOCH FROM NOW())::INTEGER::TEXT),
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

-- Function to generate QR attendance codes
CREATE OR REPLACE FUNCTION public.generate_attendance_qr_code()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    qr_prefix TEXT;
    random_suffix TEXT;
BEGIN
    -- Get QR code prefix from config
    SELECT qr_code_prefix INTO qr_prefix FROM public.qr_attendance_config LIMIT 1;
    
    -- If no config exists, use default
    IF qr_prefix IS NULL THEN
        qr_prefix := 'VERRA_ATT';
    END IF;
    
    -- Generate random suffix
    random_suffix := upper(substr(md5(random()::text), 1, 8));
    
    RETURN qr_prefix || '_' || TO_CHAR(CURRENT_DATE, 'YYYYMMDD') || '_' || random_suffix;
END;
$$;

-- Function to validate QR code for attendance
CREATE OR REPLACE FUNCTION public.validate_qr_attendance_code(qr_code_input TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    config_prefix TEXT;
    today_date_str TEXT;
BEGIN
    -- Get configuration
    SELECT qr_code_prefix INTO config_prefix FROM public.qr_attendance_config LIMIT 1;
    
    -- Use default if no config
    IF config_prefix IS NULL THEN
        config_prefix := 'VERRA_ATT';
    END IF;
    
    -- Get today's date string
    today_date_str := TO_CHAR(CURRENT_DATE, 'YYYYMMDD');
    
    -- Validate QR code format: PREFIX_YYYYMMDD_RANDOMSTRING
    RETURN qr_code_input LIKE config_prefix || '_' || today_date_str || '_%' 
           AND length(qr_code_input) > length(config_prefix || '_' || today_date_str || '_');
END;
$$;

-- 5. Enable RLS
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.leave_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.qr_attendance_config ENABLE ROW LEVEL SECURITY;

-- 6. RLS Policies using Pattern 1 & 2 (Simple, Direct)

-- Pattern 1: Core user table (user_profiles) - Simple only, no functions
CREATE POLICY "users_manage_own_user_profiles"
ON public.user_profiles
FOR ALL
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

-- Pattern 2: Simple user ownership for attendance
CREATE POLICY "users_manage_own_attendance_records"
ON public.attendance_records
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Pattern 2: Simple user ownership for leave requests
CREATE POLICY "users_manage_own_leave_requests"
ON public.leave_requests
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Pattern 2: Users view own notifications
CREATE POLICY "users_view_own_notifications"
ON public.notifications
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- QR config - managers and admins can view and modify
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

-- Managers can access QR attendance configuration
CREATE POLICY "managers_access_qr_config"
ON public.qr_attendance_config
FOR ALL
TO authenticated
USING (public.is_manager_from_auth())
WITH CHECK (public.is_manager_from_auth());

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

CREATE TRIGGER handle_updated_at_qr_config
    BEFORE UPDATE ON public.qr_attendance_config
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 8. Initialize Default Configuration
DO $$
DECLARE
    default_config_id UUID := gen_random_uuid();
BEGIN
    -- Insert default QR attendance configuration for Verra organization
    INSERT INTO public.qr_attendance_config (
        id, organization_name, qr_code_prefix, location_validation_enabled,
        allowed_latitude, allowed_longitude, geofence_radius_meters,
        work_start_time, work_end_time, late_threshold_minutes
    ) VALUES (
        default_config_id, 'Verra Organization', 'VERRA_ATT', true,
        40.7128, -74.0060, 100,
        '09:00:00', '17:00:00', 15
    );
    
    RAISE NOTICE 'Default QR attendance configuration created for Verra Organization';
END $$;

-- 9. Mock Data with Complete Auth Users for Testing
DO $$
DECLARE
    admin_uuid UUID := gen_random_uuid();
    manager_uuid UUID := gen_random_uuid();
    employee1_uuid UUID := gen_random_uuid();
    employee2_uuid UUID := gen_random_uuid();
    sample_qr_code TEXT;
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
         'admin@verra.org', crypt('admin123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Verra Admin", "employee_id": "VER001", "role": "admin"}'::jsonb, 
         '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (manager_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'manager@verra.org', crypt('manager123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Verra Manager", "employee_id": "VER002", "role": "manager"}'::jsonb, 
         '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (employee1_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'employee1@verra.org', crypt('staff123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "John Smith", "employee_id": "VER003", "role": "employee"}'::jsonb, 
         '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (employee2_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'employee2@verra.org', crypt('staff456', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Maria Garcia", "employee_id": "VER004", "role": "employee"}'::jsonb, 
         '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null);

    -- Generate sample QR code for testing
    SELECT public.generate_attendance_qr_code() INTO sample_qr_code;

    -- Sample attendance records with QR codes
    INSERT INTO public.attendance_records (user_id, date, check_in_time, check_out_time, status, qr_code, location_lat, location_lng, notes) VALUES
        (employee1_uuid, CURRENT_DATE, 
         CURRENT_DATE + INTERVAL '9 hours', 
         CURRENT_DATE + INTERVAL '17 hours', 'present', sample_qr_code, 40.7128, -74.0060, 'QR Check-in via mobile app'),
        (employee2_uuid, CURRENT_DATE, 
         CURRENT_DATE + INTERVAL '9 hours 15 minutes', 
         CURRENT_DATE + INTERVAL '17 hours 30 minutes', 'late', sample_qr_code, 40.7130, -74.0062, 'QR Check-in via mobile app'),
        (employee1_uuid, CURRENT_DATE - INTERVAL '1 day', 
         CURRENT_DATE - INTERVAL '1 day' + INTERVAL '9 hours', 
         CURRENT_DATE - INTERVAL '1 day' + INTERVAL '17 hours', 'present', 'VERRA_ATT_' || TO_CHAR(CURRENT_DATE - INTERVAL '1 day', 'YYYYMMDD') || '_SAMPLE01', 40.7126, -74.0058, 'Previous day attendance');

    -- Sample leave requests
    INSERT INTO public.leave_requests (user_id, leave_type, start_date, end_date, total_days, reason, status) VALUES
        (employee1_uuid, 'vacation', CURRENT_DATE + INTERVAL '7 days', 
         CURRENT_DATE + INTERVAL '9 days', 3, 'Annual family vacation', 'approved'),
        (employee2_uuid, 'sick', CURRENT_DATE + INTERVAL '2 days', 
         CURRENT_DATE + INTERVAL '3 days', 2, 'Medical appointment and recovery', 'pending');

    -- Sample notifications
    INSERT INTO public.notifications (user_id, title, message, type) VALUES
        (employee1_uuid, 'Leave Approved', 'Your vacation leave request has been approved by management.', 'success'),
        (employee2_uuid, 'QR Code Updated', 'Daily QR code for attendance has been refreshed. Please use the new code.', 'info'),
        (manager_uuid, 'New Leave Request', 'Maria Garcia has submitted a new sick leave request for review.', 'warning');

EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'Foreign key error: %', SQLERRM;
    WHEN unique_violation THEN
        RAISE NOTICE 'Unique constraint error: %', SQLERRM;
    WHEN OTHERS THEN
        RAISE NOTICE 'Unexpected error: %', SQLERRM;
END $$;

-- 10. Cleanup function for development
CREATE OR REPLACE FUNCTION public.cleanup_verra_mock_data()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    mock_user_ids UUID[];
BEGIN
    -- Get mock user IDs for Verra organization
    SELECT ARRAY_AGG(id) INTO mock_user_ids
    FROM auth.users
    WHERE email LIKE '%@verra.org';

    -- Delete in dependency order
    DELETE FROM public.notifications WHERE user_id = ANY(mock_user_ids);
    DELETE FROM public.leave_requests WHERE user_id = ANY(mock_user_ids);
    DELETE FROM public.attendance_records WHERE user_id = ANY(mock_user_ids);
    DELETE FROM public.user_profiles WHERE id = ANY(mock_user_ids);
    DELETE FROM auth.users WHERE id = ANY(mock_user_ids);
    
    -- Clean up QR config (keep default for organization)
    -- DELETE FROM public.qr_attendance_config; -- Uncomment if needed

    RAISE NOTICE 'Verra organization mock data cleanup completed';
EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'Foreign key constraint prevents deletion: %', SQLERRM;
    WHEN OTHERS THEN
        RAISE NOTICE 'Cleanup failed: %', SQLERRM;
END;
$$;

-- 11. Daily QR Code Generation Function (for automated systems)
CREATE OR REPLACE FUNCTION public.get_daily_qr_code()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    daily_qr TEXT;
BEGIN
    -- Generate or retrieve daily QR code
    daily_qr := public.generate_attendance_qr_code();
    
    -- Log the generation for audit
    INSERT INTO public.notifications (
        user_id, title, message, type, data
    ) 
    SELECT 
        up.id, 
        'Daily QR Code', 
        'New attendance QR code generated for ' || TO_CHAR(CURRENT_DATE, 'YYYY-MM-DD'),
        'system',
        jsonb_build_object('qr_code', daily_qr, 'date', CURRENT_DATE)
    FROM public.user_profiles up
    WHERE up.role IN ('admin', 'manager');
    
    RETURN daily_qr;
END;
$$;