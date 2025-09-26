-- ============================================================
-- File: 20250923145243_attendance_management_with_auth.sql
-- Purpose: Full attendance & leave-management schema with auth
-- ============================================================

-- 1. Extensions & Types --------------------------------------
create extension if not exists pgcrypto;

create type public.user_role         as enum ('admin','manager','employee');
create type public.attendance_status as enum ('present','absent','late','half_day');
create type public.leave_status      as enum ('pending','approved','rejected');
create type public.leave_type        as enum ('sick','casual','vacation','maternity','paternity','emergency');

-- 2. Core Tables ---------------------------------------------
create table public.user_profiles (
    id              uuid primary key references auth.users(id) on delete cascade,
    employee_id     text not null unique,
    email           text not null unique,
    full_name       text not null,
    phone           text,
    department      text,
    position        text,
    role            public.user_role default 'employee',
    is_active       boolean default true,
    profile_image_url text,
    created_at      timestamptz default current_timestamp,
    updated_at      timestamptz default current_timestamp
);

create table public.attendance_records (
    id              uuid primary key default gen_random_uuid(),
    user_id         uuid references public.user_profiles(id) on delete cascade,
    date            date not null,
    check_in_time   timestamptz,
    check_out_time  timestamptz,
    status          public.attendance_status default 'present',
    location_lat    decimal(10,8),
    location_lng    decimal(11,8),
    notes           text,
    created_at      timestamptz default current_timestamp,
    updated_at      timestamptz default current_timestamp
);

create table public.leave_requests (
    id            uuid primary key default gen_random_uuid(),
    user_id       uuid references public.user_profiles(id) on delete cascade,
    leave_type    public.leave_type not null,
    start_date    date not null,
    end_date      date not null,
    total_days    integer not null,
    reason        text not null,
    status        public.leave_status default 'pending',
    approved_by   uuid references public.user_profiles(id) on delete set null,
    approved_at   timestamptz,
    manager_notes text,
    created_at    timestamptz default current_timestamp,
    updated_at    timestamptz default current_timestamp
);

create table public.notifications (
    id         uuid primary key default gen_random_uuid(),
    user_id    uuid references public.user_profiles(id) on delete cascade,
    title      text not null,
    message    text not null,
    type       text default 'info',
    is_read    boolean default false,
    data       jsonb,
    created_at timestamptz default current_timestamp
);

-- 3. Indexes --------------------------------------------------
create index idx_user_profiles_employee_id    on public.user_profiles(employee_id);
create index idx_user_profiles_email          on public.user_profiles(email);
create index idx_attendance_records_user_id   on public.attendance_records(user_id);
create index idx_attendance_records_date      on public.attendance_records(date);
create index idx_attendance_records_user_date on public.attendance_records(user_id, date);
create index idx_leave_requests_user_id       on public.leave_requests(user_id);
create index idx_leave_requests_status        on public.leave_requests(status);
create index idx_notifications_user_id        on public.notifications(user_id);
create index idx_notifications_is_read        on public.notifications(user_id, is_read);

-- 4. Functions -----------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer as $$
begin
    insert into public.user_profiles (id,email,full_name,employee_id,role)
    values (
        new.id,
        new.email,
        coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email,'@',1)),
        coalesce(new.raw_user_meta_data->>'employee_id','EMP' || extract(epoch from now())::int::text),
        coalesce((new.raw_user_meta_data->>'role')::public.user_role,'employee')
    );
    return new;
end;
$$;

create or replace function public.handle_updated_at()
returns trigger
language plpgsql
security definer as $$
begin
    new.updated_at = current_timestamp;
    return new;
end;
$$;

create or replace function public.is_manager_from_auth()
returns boolean
language sql
stable
security definer as $$
select exists (
    select 1 from auth.users au
    where au.id = auth.uid()
      and (au.raw_user_meta_data->>'role' in ('admin','manager')
           or au.raw_app_meta_data->>'role' in ('admin','manager'))
);
$$;

-- 5. RLS & Policies ------------------------------------------
alter table public.user_profiles      enable row level security;
alter table public.attendance_records enable row level security;
alter table public.leave_requests     enable row level security;
alter table public.notifications      enable row level security;

create policy users_manage_own_user_profiles
on public.user_profiles
for all to authenticated
using (id = auth.uid())
with check (id = auth.uid());

create policy users_manage_own_attendance_records
on public.attendance_records
for all to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy users_manage_own_leave_requests
on public.leave_requests
for all to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy users_view_own_notifications
on public.notifications
for select to authenticated
using (user_id = auth.uid());

create policy managers_view_all_attendance
on public.attendance_records
for select to authenticated
using (public.is_manager_from_auth());

create policy managers_view_all_leave_requests
on public.leave_requests
for select to authenticated
using (public.is_manager_from_auth());

-- 6. Triggers -------------------------------------------------
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

create trigger handle_updated_at_user_profiles
before update on public.user_profiles
for each row execute function public.handle_updated_at();

create trigger handle_updated_at_attendance_records
before update on public.attendance_records
for each row execute function public.handle_updated_at();

create trigger handle_updated_at_leave_requests
before update on public.leave_requests
for each row execute function public.handle_updated_at();

-- 7. Mock/Test Data ------------------------------------------
do $$
declare
    admin_uuid    uuid := gen_random_uuid();
    manager_uuid  uuid := gen_random_uuid();
    employee1_uuid uuid := gen_random_uuid();
    employee2_uuid uuid := gen_random_uuid();
begin
    insert into auth.users (
        id,instance_id,aud,role,email,encrypted_password,email_confirmed_at,
        created_at,updated_at,raw_user_meta_data,raw_app_meta_data,
        is_sso_user,is_anonymous,confirmation_token,confirmation_sent_at,
        recovery_token,recovery_sent_at,email_change_token_new,email_change,
        email_change_sent_at,email_change_token_current,email_change_confirm_status,
        reauthentication_token,reauthentication_sent_at,phone,phone_change,
        phone_change_token,phone_change_sent_at
    ) values
        (admin_uuid,'00000000-0000-0000-0000-000000000000','authenticated','authenticated',
         'admin@barstaff.com',crypt('admin123',gen_salt('bf',10)),now(),now(),now(),
         '{"full_name":"Sarah Johnson","employee_id":"EMP001","role":"admin"}'::jsonb,
         '{"provider":"email","providers":["email"]}'::jsonb,
         false,false,'',null,'',null,'','',null,'',0,'',null,null,'','',null),
        (manager_uuid,'00000000-0000-0000-0000-000000000000','authenticated','authenticated',
         'manager@barstaff.com',crypt('manager123',gen_salt('bf',10)),now(),now(),now(),
         '{"full_name":"Mike Wilson","employee_id":"EMP002","role":"manager"}'::jsonb,
         '{"provider":"email","providers":["email"]}'::jsonb,
         false,false,'',null,'',null,'','',null,'',0,'',null,null,'','',null),
        (employee1_uuid,'00000000-0000-0000-0000-000000000000','authenticated','authenticated',
         'employee1@barstaff.com',crypt('staff123',gen_salt('bf',10)),now(),now(),now(),
         '{"full_name":"Alex Chen","employee_id":"EMP003","role":"employee"}'::jsonb,
         '{"provider":"email","providers":["email"]}'::jsonb,
         false,false,'',null,'',null,'','',null,'',0,'',null,null,'','',null),
        (employee2_uuid,'00000000-0000-0000-0000-000000000000','authenticated','authenticated',
         'employee2@barstaff.com',crypt('staff456',gen_salt('bf',10)),now(),now(),now(),
         '{"full_name":"Emma Davis","employee_id":"EMP004","role":"employee"}'::jsonb,
         '{"provider":"email","providers":["email"]}'::jsonb,
         false,false,'',null,'',null,'','',null,'',0,'',null,null,'','',null);

    insert into public.attendance_records (user_id,date,check_in_time,check_out_time,status) values
        (employee1_uuid,current_date,current_date + interval '9 hours',  current_date + interval '17 hours','present'),
        (employee2_uuid,current_date,current_date + interval '9 hours 15 minutes',current_date + interval '17 hours 30 minutes','late'),
        (employee1_uuid,current_date - interval '1 day',current_date - interval '1 day' + interval '9 hours',current_date - interval '1 day' + interval '17 hours','present');

    insert into public.leave_requests (user_id,leave_type,start_date,end_date,total_days,reason,status) values
        (employee1_uuid,'vacation',current_date + interval '7 days', current_date + interval '9 days',3,'Family vacation','approved'),
        (employee2_uuid,'sick',current_date + interval '2 days', current_date + interval '3 days',2,'Medical appointment','pending');

    insert into public.notifications (user_id,title,message,type) values
        (employee1_uuid,'Leave Approved','Your vacation leave request has been approved.','success'),
        (employee2_uuid,'Attendance Reminder','Please remember to check in on time.','warning'),
        (manager_uuid,'New Leave Request','Emma Davis has submitted a new leave request.','info');
exception
    when foreign_key_violation then
        raise notice 'Foreign key error: %', sqlerrm;
    when unique_violation then
        raise notice 'Unique constraint error: %', sqlerrm;
    when others then
        raise notice 'Unexpected error: %', sqlerrm;
end $$;

-- 8. Cleanup Function ----------------------------------------
create or replace function public.cleanup_mock_data()
returns void
language plpgsql
security definer as $$
declare
    mock_user_ids uuid[];
begin
    select array_agg(id) into mock_user_ids
    from auth.users
    where email like '%@barstaff.com';

    delete from public.notifications      where user_id = any(mock_user_ids);
    delete from public.leave_requests      where user_id = any(mock_user_ids);
    delete from public.attendance_records  where user_id = any(mock_user_ids);
    delete from public.user_profiles       where id     = any(mock_user_ids);
    delete from auth.users                 where id     = any(mock_user_ids);

    raise notice 'Mock data cleanup completed';
exception
    when foreign_key_violation then
        raise notice 'Foreign key constraint prevents deletion: %', sqlerrm;
    when others then
        raise notice 'Cleanup failed: %', sqlerrm;
end;
$$;
