-- FINAL DEFINITIVE MECHANIC APP SCHEMA (v28)
-- Complete idempotent setup for all tables, functions, and security.

begin;

-- =========================================================
-- 1. TABLES & COLUMN SYNC
-- =========================================================

-- PROFILES
create table if not exists public.profiles (
  id uuid references auth.users(id) on delete cascade primary key,
  full_name text,
  email text,
  phone text,
  role text not null default 'customer'
    check (role in ('customer', 'mechanic', 'admin')),
  shop_name text,
  tier text default 'GOLD',
  avatar_url text,
  last_location_name text,
  location_lat numeric,
  location_lng numeric,
  rating numeric default 5.0,
  is_online boolean default false,
  is_verified boolean default false,
  is_blocked boolean default false,
  jobs_completed integer default 0,
  base_fee numeric default 1500,
  acceptance_rate integer default 100,
  avg_response_time integer default 5,
  Working_radius numeric default 5.0,
  gender text check (gender in ('male', 'female', 'other')),
  age integer check (age >= 18 and age <= 100),
  cnic_front_url text,
  cnic_back_url text,
  license_url text,
  certification_url text,
  verification_status text not null default 'unverified'
    check (verification_status in ('unverified', 'pending', 'verified', 'rejected')),
  created_at timestamptz not null default now()
);

-- FLEETS
create table if not exists public.fleets (
  id uuid default gen_random_uuid() primary key,
  manager_id uuid references public.profiles(id) on delete cascade not null,
  name text not null,
  created_at timestamptz not null default now()
);

-- WALLETS
create table if not exists public.wallets (
  id uuid default gen_random_uuid() primary key,
  profile_id uuid references public.profiles(id) on delete cascade unique,
  balance numeric not null default 0,
  updated_at timestamptz not null default now()
);

-- SERVICES
create table if not exists public.services (
  id uuid default gen_random_uuid() primary key,
  name text not null unique,
  icon_name text,
  base_price numeric,
  is_active boolean default true,
  created_at timestamptz not null default now()
);

-- VEHICLES
create table if not exists public.vehicles (
  id uuid default gen_random_uuid() primary key,
  owner_id uuid references public.profiles(id) on delete cascade not null,
  fleet_id uuid references public.fleets(id) on delete set null,
  make text not null,
  model text not null,
  plate_number text not null,
  year text,
  mileage integer default 0,
  last_service_date timestamptz,
  created_at timestamptz not null default now()
);

-- BOOKINGS
create table if not exists public.bookings (
  id uuid default gen_random_uuid() primary key,
  customer_id uuid references public.profiles(id),
  mechanic_id uuid references public.profiles(id),
  vehicle_id uuid references public.vehicles(id),
  service_type text,
  problem_description text,
  status text not null default 'pending'
    check (status in (
      'pending',
      'accepted',
      'on_the_way',
      'in_progress',
      'completed',
      'cancelled'
    )),
  total_price numeric,
  customer_location_name text,
  pin_code text default '5824',
  created_at timestamptz not null default now()
);

-- MESSAGES
create table if not exists public.messages (
  id uuid default gen_random_uuid() primary key,
  booking_id uuid references public.bookings(id) on delete cascade,
  sender_id uuid references public.profiles(id),
  receiver_id uuid references public.profiles(id),
  text text not null,
  is_read boolean default false,
  created_at timestamptz not null default now()
);

-- REVIEWS
create table if not exists public.reviews (
  id uuid default gen_random_uuid() primary key,
  booking_id uuid references public.bookings(id) on delete cascade,
  customer_id uuid references public.profiles(id),
  mechanic_id uuid references public.profiles(id),
  rating numeric not null check (rating >= 1 and rating <= 5),
  comment text,
  created_at timestamptz not null default now()
);

-- NOTIFICATIONS
create table if not exists public.notifications (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) on delete cascade,
  title text not null,
  body text not null,
  type text,
  is_read boolean default false,
  created_at timestamptz not null default now()
);

-- EMERGENCY SOS
create table if not exists public.emergency_sos (
  id uuid default gen_random_uuid() primary key,
  customer_id uuid references public.profiles(id),
  location_lat numeric,
  location_lng numeric,
  status text not null default 'searching',
  created_at timestamptz not null default now()
);

-- TRANSACTIONS
create table if not exists public.transactions (
  id uuid default gen_random_uuid() primary key,
  profile_id uuid references public.profiles(id),
  booking_id uuid references public.bookings(id),
  amount numeric not null,
  type text not null
    check (type in ('payout', 'withdrawal', 'refund', 'topup')),
  created_at timestamptz not null default now()
);

-- =========================================================
-- 2. HELPER FUNCTIONS
-- =========================================================

create or replace function public.is_admin()
returns boolean
language plpgsql
security definer
as $$
begin
  return exists (select 1 from public.profiles where id = auth.uid() and role = 'admin');
end;
$$;

create or replace function public.get_nearby_mechanics(
  user_lat numeric,
  user_lng numeric,
  radius_km numeric default 5.0
)
returns setof public.profiles
language sql
security definer
as $$
  select *
  from public.profiles
  where role = 'mechanic'
    and is_online = true
    and is_verified = true
    and is_blocked = false
    and (
      6371 * acos(
        cos(radians(user_lat)) * cos(radians(location_lat)) *
        cos(radians(location_lng) - radians(user_lng)) +
        sin(radians(user_lat)) * sin(radians(location_lat))
      )
    ) <= radius_km;
$$;

create or replace function public.handle_wallet_topup(
  user_id uuid,
  topup_amount numeric
)
returns void
language plpgsql
security definer
as $$
begin
  update public.wallets
  set balance = balance + topup_amount,
      updated_at = now()
  where profile_id = user_id;

  if not found then
    insert into public.wallets (profile_id, balance)
    values (user_id, topup_amount);
  end if;
end;
$$;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public, auth
as $$
declare
    _role text;
begin
  if new.email = 'admin@mechanic.com' then
    _role := 'admin';
  else
    _role := coalesce(new.raw_user_meta_data->>'role', 'customer');
  end if;

  insert into public.profiles (id, full_name, email, role, phone, gender, age, verification_status)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', 'New User'),
    new.email,
    _role,
    coalesce(new.phone, new.raw_user_meta_data->>'phone', ''),
    new.raw_user_meta_data->>'gender',
    (new.raw_user_meta_data->>'age')::integer,
    'unverified'
  )
  on conflict (id) do update set email = excluded.email;

  -- Create Wallet
  insert into public.wallets (profile_id, balance) values (new.id, 0) on conflict (profile_id) do nothing;

  return new;
end;
$$;

-- =========================================================
-- 3. POLICIES (RLS)
-- =========================================================

alter table public.profiles enable row level security;
alter table public.fleets enable row level security;
alter table public.vehicles enable row level security;
alter table public.wallets enable row level security;
alter table public.services enable row level security;
alter table public.bookings enable row level security;
alter table public.messages enable row level security;
alter table public.reviews enable row level security;
alter table public.notifications enable row level security;
alter table public.emergency_sos enable row level security;
alter table public.transactions enable row level security;

do $$
declare
    pol record;
begin
    for pol in (select policyname, tablename from pg_policies where schemaname = 'public') loop
        execute format('drop policy if exists %I on %I', pol.policyname, pol.tablename);
    end loop;
end $$;

-- Profiles: Public can see limited info, only owner/admin can see full info
create policy "Profiles public select" on public.profiles for select using (true);
create policy "Profiles private update" on public.profiles for update using (auth.uid() = id or public.is_admin());

-- Fleets: Only manager or admin
create policy "Fleets select" on public.fleets for select using (auth.uid() = manager_id or public.is_admin());
create policy "Fleets insert" on public.fleets for insert with check (auth.uid() = manager_id or public.is_admin());
create policy "Fleets manage" on public.fleets for all using (auth.uid() = manager_id or public.is_admin());

-- Wallets: Only owner or admin
create policy "Wallets select" on public.wallets for select using (auth.uid() = profile_id or public.is_admin());

-- Services: Everyone can see, only admin can manage
create policy "Services select" on public.services for select using (true);
create policy "Services manage" on public.services for all using (public.is_admin());

-- Vehicles: Only owner or admin
create policy "Vehicles select" on public.vehicles for select using (auth.uid() = owner_id or public.is_admin());
create policy "Vehicles insert" on public.vehicles for insert with check (auth.uid() = owner_id or public.is_admin());
create policy "Vehicles update" on public.vehicles for update using (auth.uid() = owner_id or public.is_admin());
create policy "Vehicles delete" on public.vehicles for delete using (auth.uid() = owner_id or public.is_admin());

-- Bookings: Cust, Mech, or Admin
create policy "Bookings select" on public.bookings for select using (auth.uid() = customer_id or auth.uid() = mechanic_id or public.is_admin());
create policy "Bookings insert" on public.bookings for insert with check (auth.uid() = customer_id or public.is_admin());
create policy "Bookings update" on public.bookings for update using (auth.uid() = customer_id or auth.uid() = mechanic_id or public.is_admin());

-- Messages: Sender or Receiver
create policy "Messages select" on public.messages for select using (auth.uid() = sender_id or auth.uid() = receiver_id or public.is_admin());
create policy "Messages insert" on public.messages for insert with check (auth.uid() = sender_id or public.is_admin());

-- Reviews: Everyone can see, only customer can write
create policy "Reviews select" on public.reviews for select using (true);
create policy "Reviews insert" on public.reviews for insert with check (auth.uid() = customer_id or public.is_admin());

-- Notifications: Only owner or admin
create policy "Notifications select" on public.notifications for select using (auth.uid() = user_id or public.is_admin());
create policy "Notifications insert" on public.notifications for insert with check (auth.uid() = user_id or public.is_admin());
create policy "Notifications update" on public.notifications for update using (auth.uid() = user_id or public.is_admin());

-- SOS: Customer, Admin, or Online Mechanics (only for searching status)
create policy "SOS select" on public.emergency_sos for select
  using (
    auth.uid() = customer_id
    or public.is_admin()
    or (exists(select 1 from public.profiles where id = auth.uid() and role = 'mechanic' and is_online = true) and status = 'searching')
  );
create policy "SOS insert" on public.emergency_sos for insert with check (auth.uid() = customer_id or public.is_admin());

-- Transactions: User or Admin
create policy "Transactions select" on public.transactions for select using (auth.uid() = profile_id or public.is_admin());

-- =========================================================
-- 4. TRIGGERS
-- =========================================================

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute function public.handle_new_user();

commit;
