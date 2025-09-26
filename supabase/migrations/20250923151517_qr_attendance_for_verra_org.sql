-- ============================================================
-- QR-Based Attendance System for Verra Organization
-- ============================================================

-- 1. ENUM TYPES ------------------------------------------------
CREATE TYPE public.user_role       AS ENUM ('admin', 'manager', 'employee');
CREATE TYPE public.attendance_status AS ENUM ('present', 'absent', 'late', 'half_day');
CREATE TYPE public.leave_status      AS ENUM ('pending', 'approved', 'rejected');
CREATE TYPE public.leave_type        AS ENUM ('sick', 'casual', 'vacation', 'maternity', 'paternity', 'emergency');

-- 2. TABLES ----------------------------------------------------

-- User profiles linked to auth.users
CREATE TABLE public.user_profiles (
    id              UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    employee_id     TEXT NOT NULL UNIQUE,
    email           TEXT NOT NULL UNIQUE,
    full_name       TEXT NOT NULL,
    phone           TEXT,
    department      TEXT,
    position        TEXT,
    role            public.user_role DEFAULT 'employee',
    is_active       BOOLEAN DEFAULT true,
    profile_image_url TEXT,
    created_at      TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Attendance records
CREATE TABLE public.attendance_records (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    date            DATE NOT NULL,
    check_in_time   TIMESTAMPTZ,
    check_out_time  TIMESTAMPTZ,
    status          public.attendance_status DEFAULT 'present',
    location_lat    DECIMAL(10,8),
    location_lng    DECIMAL(11,8),
    qr_code         TEXT,
    notes           TEXT,
    created_at      TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Organization QR-code settings
CREATE TABLE public.qr_attendance_config (
    id                       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_name        TEXT NOT NULL DEFAULT 'Verra Organization',
    qr_code_prefix           TEXT NOT NULL DEFAULT 'VERRA_ATT',
    location_validation_enabled BOOLEAN DEFAULT true,
    allowed_latitude         DECIMAL(10,8) DEFAULT 40.7128,
    allowed_longitude        DECIMAL(11,8) DEFAULT -74.0060,
    geofence_radius_meters   INTEGER DEFAULT 100,
    work_start_time          TIME DEFAULT '09:00:00',
    work_end_time            TIME DEFAULT '17:00:00',
    late_threshold_minutes   INTEGER DEFAULT 15,
    created_at               TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at               TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Leave requests
CREATE TABLE public.leave_requests (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    leave_type    public.leave_type NOT NULL,
    start_date    DATE NOT NULL,
    end_date      DATE NOT NULL,
    total_days    INTEGER NOT NULL,
    reason        TEXT NOT NULL,
    status        public.leave_status DEFAULT 'pending',
    approved_by   UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    approved_at   TIMESTAMPTZ,
    manager_notes TEXT,
    created_at    TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Notifications
CREATE TABLE public.notifications (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    title      TEXT NOT NULL,
    message    TEXT NOT NULL,
    type       TEXT DEFAULT 'info',
    is_read    BOOLEAN DEFAULT false,
    data       JSONB,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 3. INDEXES ---------------------------------------------------
CREATE INDEX idx_user_profiles_employee_id    ON public.user_profiles(employee_id);
CREATE INDEX idx_user_profiles_email          ON public.user_profiles(email);
CREATE INDEX idx_attendance_records_user_id   ON public.attendance_records(user_id);
CREATE INDEX idx_attendance_records_date      ON public.attendance_records(date);
CREATE INDEX idx_attendance_records_user_date ON public.attendance_records(user_id, date);
CREATE INDEX idx_attendance_records_qr_code   ON public.attendance_records(qr_code);
CREATE INDEX idx_leave_requests_user_id       ON public.leave_requests(user_id);
CREATE INDEX idx_leave_requests_status        ON public.leave_requests(status);
CREATE INDEX idx_notifications_user_id        ON public.notifications(user_id);
CREATE INDEX idx_notifications_is_read        ON public.notifications(user_id, is_read);

-- 4. FUNCTIONS -------------------------------------------------
-- Auto-create user_profile on new auth.user
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    INSERT INTO public.user_profiles (id,email,full_name,employee_id,role)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email,'@',1)),
        COALESCE(NEW.raw_user_meta_data->>'employee_id','VER'||EXTRACT(EPOCH FROM NOW())::INT::TEXT),
        COALESCE((NEW.raw_user_meta_data->>'role')::public.user_role,'employee')
    );
    RETURN NEW;
END;
$$;

-- Update updated_at on change
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

-- Generate QR code
CREATE OR REPLACE FUNCTION public.generate_attendance_qr_code()
RETURNS TEXT LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    pfx TEXT; rnd TEXT;
BEGIN
    SELECT qr_code_prefix INTO pfx FROM public.qr_attendance_config LIMIT 1;
    IF pfx IS NULL THEN pfx := 'VERRA_ATT'; END IF;
    rnd := upper(substr(md5(random()::text),1,8));
    RETURN pfx || '_' || TO_CHAR(CURRENT_DATE,'YYYYMMDD') || '_' || rnd;
END;
$$;

-- Validate QR code format
CREATE OR REPLACE FUNCTION public.validate_qr_attendance_code(qr_code_input TEXT)
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE pfx TEXT; today TEXT;
BEGIN
    SELECT qr_code_prefix INTO pfx FROM public.qr_attendance_config LIMIT 1;
    IF pfx IS NULL THEN pfx := 'VERRA_ATT'; END IF;
    today := TO_CHAR(CURRENT_DATE,'YYYYMMDD');
    RETURN qr_code_input LIKE pfx || '_' || today || '_%';
END;
$$;

-- Check if current user is admin/manager
CREATE OR REPLACE FUNCTION public.is_manager_from_auth()
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER AS $$
SELECT EXISTS (
    SELECT 1 FROM auth.users
    WHERE id = auth.uid()
      AND (raw_user_meta_data->>'role' IN ('admin','manager')
           OR raw_app_meta_data->>'role' IN ('admin','manager'))
);
$$;

-- 5. RLS & POLICIES -------------------------------------------
ALTER TABLE public.user_profiles       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance_records  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.leave_requests      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.qr_attendance_config ENABLE ROW LEVEL SECURITY;

CREATE POLICY users_manage_own_user_profiles
ON public.user_profiles
FOR ALL TO authenticated
USING (id = auth.uid()) WITH CHECK (id = auth.uid());

CREATE POLICY users_manage_own_attendance_records
ON public.attendance_records
FOR ALL TO authenticated
USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

CREATE POLICY users_manage_own_leave_requests
ON public.leave_requests
FOR ALL TO authenticated
USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

CREATE POLICY users_view_own_notifications
ON public.notifications
FOR SELECT TO authenticated
USING (user_id = auth.uid());

CREATE POLICY managers_view_all_attendance
ON public.attendance_records
FOR SELECT TO authenticated
USING (public.is_manager_from_auth());

CREATE POLICY managers_view_all_leave_requests
ON public.leave_requests
FOR SELECT TO authenticated
USING (public.is_manager_from_auth());

CREATE POLICY managers_access_qr_config
ON public.qr_attendance_config
FOR ALL TO authenticated
USING (public.is_manager_from_auth())
WITH CHECK (public.is_manager_from_auth());

-- 6. TRIGGERS --------------------------------------------------
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

-- 7. DEFAULT CONFIG -------------------------------------------
INSERT INTO public.qr_attendance_config
(organization_name) VALUES ('Verra Organization')
ON CONFLICT DO NOTHING;
