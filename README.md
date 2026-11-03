# Rekapitulasi LKBB Artemis Chapter 2 — GitHub Pages + Supabase

Situs statis (GitHub Pages) dengan penyimpanan online di Supabase. Data bisa dilihat dari perangkat mana saja
oleh akun yang punya izin. Hak akses ditegakkan di database (Row Level Security), bukan hanya di tampilan.

## 1. Siapkan Supabase (gratis)
1. Daftar di https://supabase.com, buat **New project**.
2. Buka **SQL Editor > New query**, tempel isi `supabase/schema.sql` (sampai sebelum bagian komentar "SETELAH"), klik **Run**.
3. Buka **Authentication > Users > Add user > Create new user**. Buat dua akun (centang *Auto Confirm User*):
   - email `panitia@lkbb.local`, password pilihan Anda
   - email `peserta@lkbb.local`, password pilihan Anda
   (Login di web memakai *username* `panitia` / `peserta`; web otomatis menambahkan `@lkbb.local`.
   Ingin peserta punya akun per sekolah? Buat `namasekolah@lkbb.local` dan daftarkan role `peserta`.)
4. Kembali ke SQL Editor, jalankan dua perintah `insert into public.profiles ...` yang ada di bagian bawah `schema.sql`
   (hapus tanda `--` di depannya). Untuk akun tambahan, ulangi dengan username/email-nya.
5. **Project Settings > API**: salin *Project URL* dan *anon public key*.
6. Buka `index.html`, isi `SUPABASE_URL` dan `SUPABASE_ANON_KEY` di bagian atas script.
   Kunci *anon* memang aman ditaruh di repo publik karena dilindungi RLS.
   **Jangan pernah** memasukkan kunci `service_role`.
7. (Disarankan) Authentication > Providers > Email: matikan *Allow new users to sign up* agar orang luar tidak bisa mendaftar.

## 2. Publikasi di GitHub Pages
1. Buat repository baru di GitHub, unggah semua berkas folder ini.
2. **Settings > Pages > Build and deployment > Source: Deploy from a branch**, pilih branch `main` dan folder `/ (root)`.
3. Tunggu 1 sampai 2 menit, situs tersedia di `https://<username>.github.io/<nama-repo>/`.

## Hak akses
| Aksi | Panitia | Peserta |
|---|---|---|
| Melihat nilai & peringkat | ya | ya |
| Tambah / ubah / hapus / reset | ya | tidak (ditolak database) |
| Dashboard & log aktivitas | ya | tidak |

Juara Utama dan Juara Umum dihitung oleh database (kolom *generated*), peringkat dihitung oleh view `peserta_ranked`
dengan urutan Juara Utama, PBB, VARFOR, DANTON, KOSTUM. Halaman peserta menyegarkan data tiap 5 detik.
Download Excel menghasilkan `.xlsx`; Download PDF memakai dialog cetak browser (pilih *Save as PDF*).
