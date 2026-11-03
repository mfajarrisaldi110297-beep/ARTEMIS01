-- Jalankan seluruh isi berkas ini di Supabase: SQL Editor > New query > Run

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique not null,
  role text not null check (role in ('panitia','peserta'))
);

create table if not exists public.peserta_penilaian (
  id bigint generated always as identity primary key,
  tingkatan text not null check (tingkatan in ('SD','SMP','SMA','PURNA')),
  nama_sekolah text not null check (char_length(trim(nama_sekolah)) between 1 and 150),
  nilai_pbb numeric not null default 0 check (nilai_pbb >= 0),
  nilai_varfor numeric not null default 0 check (nilai_varfor >= 0),
  nilai_danton numeric not null default 0 check (nilai_danton >= 0),
  nilai_kostum numeric not null default 0 check (nilai_kostum >= 0),
  nilai_makeup numeric not null default 0 check (nilai_makeup >= 0),
  -- dihitung otomatis oleh database, tidak bisa diinput manual
  juara_utama numeric generated always as (nilai_pbb + nilai_varfor + nilai_danton) stored,
  juara_umum numeric generated always as (nilai_pbb + nilai_varfor + nilai_danton + nilai_kostum) stored,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists idx_peserta_tingkatan on public.peserta_penilaian(tingkatan);

create table if not exists public.aktivitas (
  id bigint generated always as identity primary key,
  username text, keterangan text not null, waktu timestamptz not null default now()
);

create or replace function public.touch_updated_at() returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end $$;
drop trigger if exists trg_touch on public.peserta_penilaian;
create trigger trg_touch before update on public.peserta_penilaian
  for each row execute function public.touch_updated_at();

-- Peringkat: Juara Utama, lalu PBB, VARFOR, DANTON, KOSTUM
create or replace view public.peserta_ranked with (security_invoker = true) as
select p.*, row_number() over (
  partition by tingkatan
  order by juara_utama desc, nilai_pbb desc, nilai_varfor desc, nilai_danton desc, nilai_kostum desc, id asc
) as peringkat
from public.peserta_penilaian p;

create or replace function public.is_panitia() returns boolean
language sql security definer set search_path = public stable as $$
  select exists (select 1 from public.profiles where id = auth.uid() and role = 'panitia')
$$;

-- Hak akses ditegakkan di database (Row Level Security)
alter table public.profiles enable row level security;
alter table public.peserta_penilaian enable row level security;
alter table public.aktivitas enable row level security;

create policy "profil sendiri" on public.profiles for select to authenticated using (id = auth.uid());
create policy "login boleh baca nilai" on public.peserta_penilaian for select to authenticated using (true);
create policy "panitia tambah" on public.peserta_penilaian for insert to authenticated with check (public.is_panitia());
create policy "panitia ubah" on public.peserta_penilaian for update to authenticated using (public.is_panitia()) with check (public.is_panitia());
create policy "panitia hapus" on public.peserta_penilaian for delete to authenticated using (public.is_panitia());
create policy "panitia baca aktivitas" on public.aktivitas for select to authenticated using (public.is_panitia());
create policy "panitia catat aktivitas" on public.aktivitas for insert to authenticated with check (public.is_panitia());

revoke all on public.profiles, public.peserta_penilaian, public.peserta_ranked, public.aktivitas from anon;
grant select on public.peserta_ranked to authenticated;

-- SETELAH membuat 2 user di Authentication > Users (lihat README), jalankan:
-- insert into public.profiles (id, username, role)
--   select id, 'panitia', 'panitia' from auth.users where email = 'panitia@lkbb.local';
-- insert into public.profiles (id, username, role)
--   select id, 'peserta', 'peserta' from auth.users where email = 'peserta@lkbb.local';
