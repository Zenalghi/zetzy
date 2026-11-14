# Panduan Menghubungkan Zetzy ke Supabase

Aplikasi **Zetzy** dirancang *offline-first* (tetap berjalan penuh secara lokal tanpa backend), dan otomatis mengaktifkan **Cloud Auth, Cloud Save Progression, Global Leaderboard, Avatar Storage, Password Recovery, dan Online Chess Realtime** ketika kredensial Supabase diberikan melalui `--dart-define`.

Konfigurasi pembacaan kredensial ada di `lib/core/constants/supabase_schema.dart` (`SupabaseConfig`) dan `lib/data/remote/supabase_service.dart` (`SupabaseService`).

---

## Langkah 1 — Buat Project di Supabase

1. Buka [Supabase Dashboard](https://supabase.com/dashboard) dan login.
2. Klik **New project**.
3. Pilih **Organization**, isi:
   - **Name**: `zetzy` (atau nama sesuai keinginan)
   - **Database Password**: simpan password ini dengan aman
   - **Region**: pilih yang terdekat dengan pengguna (misalnya `Singapore (ap-southeast-1)` untuk Indonesia)
4. Klik **Create new project** dan tunggu hingga status project aktif (*Project is ready*).

---

## Langkah 2 — Jalankan SQL Schema & Policies

1. Di sidebar kiri Supabase Dashboard, buka **SQL Editor** → klik **New query**.
2. Copy-paste seluruh SQL berikut (isi ini juga tersedia di `lib/core/constants/supabase_schema.dart` dan dapat disalin dari dalam app lewat tab **Profile → View Supabase SQL Schema**):

```sql
-- Run in Supabase SQL Editor (Zetzy Schema + Anti-Cheat + Recovery RPC)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 1. User Profiles
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  username TEXT UNIQUE NOT NULL CHECK (username ~ '^[a-z0-9_]{3,16}$'),
  avatar_url TEXT,
  chess_elo INT NOT NULL DEFAULT 1000,
  recovery_hash TEXT DEFAULT NULL,
  unlocked_levels JSONB NOT NULL DEFAULT '{"sudoku": 5, "chess": 5, "minesweeper": 5, "snake": 5}'::jsonb,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Game Records & Leaderboard
CREATE TABLE IF NOT EXISTS public.game_records (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  game_type TEXT NOT NULL CHECK (game_type IN ('sudoku', 'chess', 'minesweeper', 'snake')),
  difficulty INT NOT NULL CHECK (difficulty BETWEEN 1 AND 7),
  is_won BOOLEAN NOT NULL,
  score INT NOT NULL DEFAULT 0,
  duration_ms INT NOT NULL CHECK (duration_ms >= 3000),
  platform TEXT NOT NULL CHECK (platform IN ('android', 'web', 'windows', 'linux', 'ios', 'macos')),
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  played_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_leaderboard
  ON public.game_records (game_type, difficulty, is_won, score DESC, duration_ms ASC);

-- 3. Row-Level Security & Anti-Cheat Constraint (PRD 72A)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.game_records ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public profiles readable" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Users manage own profile" ON public.profiles FOR ALL USING (auth.uid() = id);

CREATE POLICY "Public leaderboard readable" ON public.game_records FOR SELECT USING (true);
CREATE POLICY "Insert own valid records" ON public.game_records FOR INSERT WITH CHECK (
  auth.uid() = user_id AND
  NOT (game_type = 'sudoku' AND difficulty = 7 AND is_won = true AND duration_ms < 10000)
);
CREATE POLICY "Delete own records" ON public.game_records FOR DELETE USING (auth.uid() = user_id);

-- 4. Storage Bucket & Policies for Avatars (256x256 PNG)
INSERT INTO storage.buckets (id, name, public) VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "Avatar images are publicly accessible" ON storage.objects;
CREATE POLICY "Avatar images are publicly accessible"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'avatars');

DROP POLICY IF EXISTS "Users can upload own avatar" ON storage.objects;
CREATE POLICY "Users can upload own avatar"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'avatars' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

DROP POLICY IF EXISTS "Users can update own avatar" ON storage.objects;
CREATE POLICY "Users can update own avatar"
  ON storage.objects FOR UPDATE TO authenticated
  USING (
    bucket_id = 'avatars' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

DROP POLICY IF EXISTS "Users can delete own avatar" ON storage.objects;
CREATE POLICY "Users can delete own avatar"
  ON storage.objects FOR DELETE TO authenticated
  USING (
    bucket_id = 'avatars' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

-- 5. Recovery Phrase Password Reset RPC (PRD 16B)
CREATE OR REPLACE FUNCTION public.reset_password_with_recovery(
  p_username TEXT,
  p_recovery_phrase TEXT,
  p_new_password TEXT
) RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions, auth
AS $$
DECLARE
  v_user_id UUID;
  v_hash TEXT;
BEGIN
  SELECT id, recovery_hash INTO v_user_id, v_hash
  FROM public.profiles
  WHERE username = p_username;

  IF v_user_id IS NULL OR v_hash IS NULL THEN
    RETURN FALSE;
  END IF;

  IF v_hash = encode(digest(trim(p_recovery_phrase), 'sha256'), 'hex') THEN
    UPDATE auth.users
    SET encrypted_password = crypt(p_new_password, gen_salt('bf')),
        updated_at = NOW()
    WHERE id = v_user_id;
    RETURN TRUE;
  END IF;

  RETURN FALSE;
END;
$$;

-- 6. Self-Service Account Deletion RPC (PRD 18A)
CREATE OR REPLACE FUNCTION public.delete_own_account()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  DELETE FROM auth.users WHERE id = auth.uid();
END;
$$;
```

3. Klik **Run** (atau `Cmd/Ctrl + Enter`). Pastikan muncul pesan sukses (`Success. No rows returned` atau query berhasil tanpa error).
4. Cek hasil di sidebar **Table Editor**: tabel `profiles` dan `game_records` sudah muncul. Cek di **Storage**: bucket `avatars` berstatus **Public**.

---

## Langkah 3 — Atur Supabase Authentication (PENTING)

Zetzy memakai sistem akun **username-only tanpa verifikasi email** (secara internal mengubah `username` menjadi `username@arcade.local` di `ValidationRules.dummyEmailFor`). Karena domain `@arcade.local` tidak bisa menerima email sungguhan, **konfirmasi email wajib dimatikan**:

1. Buka **Authentication → Sign In / Providers** (atau **Providers → Email**).
2. Pastikan **Enable Email provider** = **ON**.
3. Pastikan **Confirm email** = **OFF** *(wajib dimatikan agar user yang baru daftar langsung mendapatkan session aktif tanpa klik link email)*.
4. Klik **Save**.

> **Catatan keamanan:** Zetzy menerapkan Single Active Session (`signOut(scope: SignOutScope.others)`) setiap kali login/register, sesuai PRD. Password reset tanpa email menggunakan RPC `reset_password_with_recovery` dengan recovery phrase yang di-hash SHA-256.

---

## Langkah 4 — Ambil Project URL & API Key

1. Buka **Project Settings** (ikon roda gigi di kiri bawah) → **API** (atau **Data API** / **API Keys**).
2. Salin dua nilai ini:
   - **Project URL**: contoh `https://abcdefghijklmno.supabase.co`
   - **Anon / Publishable Key**: pilih key publik (`anon public` atau `sb_publishable_...`).
     > ⚠️ **JANGAN PERNAH** memakai `service_role` / `secret` key di aplikasi client!

---

## Langkah 5 — Sambungkan ke Aplikasi Zetzy

Aplikasi membaca dua konstanta compile-time:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

Anda bisa memilih salah satu dari 3 cara berikut:

### Opsi A — Langsung lewat CLI (`--dart-define`)

Jalankan saat development:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://PROJECT_REF.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLIC_OR_PUBLISHABLE_KEY
```

Atau saat build rilis (Android / Web / Desktop):

```bash
# Android APK / AppBundle
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://PROJECT_REF.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLIC_OR_PUBLISHABLE_KEY

# Web
flutter build web --release \
  --dart-define=SUPABASE_URL=https://PROJECT_REF.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLIC_OR_PUBLISHABLE_KEY

# macOS / Windows / Linux (jalankan di OS target masing-masing)
flutter build macos --release \
  --dart-define=SUPABASE_URL=https://PROJECT_REF.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLIC_OR_PUBLISHABLE_KEY
```

### Opsi B — Pakai File Konfigurasi Lokal `--dart-define-from-file` (Disarankan)

Agar tidak perlu mengetik key berulang kali:

1. Buat file `supabase.json` di root project (`/Users/umardani/Documents/workspace/zetzy/supabase.json`):

```json
{
  "SUPABASE_URL": "https://PROJECT_REF.supabase.co",
  "SUPABASE_ANON_KEY": "YOUR_PUBLIC_OR_PUBLISHABLE_KEY"
}
```

> File `supabase.json` sudah ditambahkan ke `.gitignore` agar kredensial Anda tidak ikut ter-commit ke Git.

2. Jalankan atau build dengan:

```bash
flutter run --dart-define-from-file=supabase.json
```

```bash
flutter build apk --release --dart-define-from-file=supabase.json
```

### Opsi C — Konfigurasi IDE (VS Code / Cursor / Antigravity)

Jika menjalankan lewat tombol Run/Debug di `.vscode/launch.json`, tambahkan `toolArgs`:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Zetzy (Supabase)",
      "request": "launch",
      "type": "dart",
      "toolArgs": [
        "--dart-define-from-file=supabase.json"
      ]
    }
  ]
}
```

---

## Langkah 6 — Verifikasi Koneksi

Setelah menjalankan app dengan `SUPABASE_URL` dan `SUPABASE_ANON_KEY`:

1. Buka tab **Profile** di Zetzy:
   - Pastikan badge/keterangan *Cloud Offline* sudah berganti menjadi form **Sign In / Register** atau status akun online.
2. Coba buat akun baru (**Register**):
   - Username: huruf kecil/angka/underscore, 3–16 karakter (misalnya `zetzy_player`).
   - Password: minimal 8 karakter dengan kombinasi huruf dan angka.
   - Opsional: isi **Recovery Phrase**.
   - Cek di Supabase **Authentication → Users** dan **Table Editor → profiles** apakah baris user & profil baru muncul.
3. Coba selesaikan 1 game (misal Sudoku Level 1):
   - Pastikan skor muncul di **Table Editor → game_records** dan tampil di tab **Leaderboard**.
4. Coba ganti avatar di **Profile**:
   - Aplikasi akan mengompres foto menjadi `256x256` PNG dan mengunggahnya ke bucket `avatars/<user_id>/avatar.png`.
5. Coba **Chess Online Room** (di halaman Chess):
   - Fitur ini menggunakan Supabase Realtime Broadcast channel (`chess_room_<ROOM_CODE>`), sehingga aktif otomatis selama Supabase sudah terkonfigurasi.

---

## Troubleshooting Umum

| Gejala / Error | Penyebab & Solusi |
|---|---|
| `Supabase is not configured` / app tetap di mode Offline | Pastikan `flutter run` atau `flutter build` memakai `--dart-define` / `--dart-define-from-file=supabase.json` (bukan hanya menaruh file tanpa flag). Lakukan full restart (bukan sekadar hot reload). |
| Gagal Register / "Email not confirmed" saat Sign In | Di Supabase Dashboard → **Authentication → Providers → Email**, pastikan **Confirm email** diset ke **OFF**. |
| Upload Avatar gagal `403` / RLS violation | Pastikan 4 policy `storage.objects` untuk bucket `avatars` pada Langkah 2 ikut dijalankan di SQL Editor. |
| Skor Sudoku Level 7 ditolak saat upload | Policy anti-cheat di SQL menolak kemenangan Sudoku Level 7 dengan `duration_ms < 10000` (di bawah 10 detik) atau record apa pun dengan `duration_ms < 3000`. |
| Reset Password dengan Recovery Phrase mengembalikan `false` | Pastikan RPC `reset_password_with_recovery` memakai `SET search_path = public, extensions, auth` dan membandingkan `encode(digest(trim(p_recovery_phrase), 'sha256'), 'hex')` seperti pada Langkah 2. |
| Koneksi gagal di Android Release / macOS | Pastikan `android/app/src/main/AndroidManifest.xml` memiliki `<uses-permission android:name="android.permission.INTERNET"/>` dan `macos/Runner/*.entitlements` memiliki `com.apple.security.network.client` (keduanya sudah ditambahkan di repo ini). |
