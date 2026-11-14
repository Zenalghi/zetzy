/// Supabase configuration & SQL schema reference for Zetzy.
///
/// Provide `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
/// at build/run time to enable cloud sync, authentication, and online Chess.
abstract final class SupabaseConfig {
  static const String url = String.fromEnvironment('SUPABASE_URL');
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;

  static const String sqlSetupGuide = '''
-- Run in Supabase SQL Editor (Zetzy Schema + Anti-Cheat + Recovery RPC)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 1. User Profiles
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  username TEXT UNIQUE NOT NULL CHECK (username ~ '^[a-z0-9_]{3,16}\$'),
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
AS \$\$
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
\$\$;

-- 6. Self-Service Account Deletion RPC (PRD 18A)
CREATE OR REPLACE FUNCTION public.delete_own_account()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS \$\$
BEGIN
  DELETE FROM auth.users WHERE id = auth.uid();
END;
\$\$;
''';
}
