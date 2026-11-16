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
2. Copy-paste seluruh SQL berikut ke SQL Editor:

```sql
-- Run in Supabase SQL Editor (Zetzy Schema + Anti-Cheat + Recovery RPC)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 1. User Profiles (aman dijalankan ulang / non-destruktif untuk DB lama)
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  username TEXT UNIQUE NOT NULL CHECK (username ~ '^[a-z0-9_]{3,16}$'),
  avatar_url TEXT,
  chess_elo INT NOT NULL DEFAULT 1000,
  recovery_hash TEXT DEFAULT NULL,
  role TEXT NOT NULL DEFAULT 'player' CHECK (role IN ('player', 'admin')),
  unlocked_levels JSONB NOT NULL DEFAULT '{"sudoku": 5, "chess": 5, "minesweeper": 5, "snake": 5}'::jsonb,
  account_data JSONB NOT NULL DEFAULT '{}'::jsonb,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Migrasi aman jika tabel profiles sudah ada sebelumnya (tanpa menghapus data)
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS role TEXT NOT NULL DEFAULT 'player',
  ADD COLUMN IF NOT EXISTS account_data JSONB NOT NULL DEFAULT '{}'::jsonb;
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_role_check;
ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_role_check CHECK (role IN ('player', 'admin'));

-- Cegah user mengubah role sendiri menjadi admin lewat REST API client
-- Perubahan role hanya diizinkan lewat Supabase Table Editor / SQL Editor / service_role
CREATE OR REPLACE FUNCTION public.protect_profile_role_column()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF auth.uid() IS NOT NULL AND current_user NOT IN ('postgres', 'supabase_admin', 'service_role') THEN
      NEW.role := 'player';
    END IF;
    RETURN NEW;
  END IF;

  IF TG_OP = 'UPDATE' AND NEW.role IS DISTINCT FROM OLD.role THEN
    IF auth.uid() IS NOT NULL AND current_user NOT IN ('postgres', 'supabase_admin', 'service_role') THEN
      RAISE EXCEPTION 'Changing profile role from client API is forbidden';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_protect_profile_role ON public.profiles;
CREATE TRIGGER trg_protect_profile_role
  BEFORE INSERT OR UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.protect_profile_role_column();

REVOKE ALL ON FUNCTION public.protect_profile_role_column() FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = (SELECT auth.uid()) AND role = 'admin'
  );
$$;

REVOKE ALL ON FUNCTION public.is_admin() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated;

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

DROP POLICY IF EXISTS "Public profiles readable" ON public.profiles;
CREATE POLICY "Public profiles readable" ON public.profiles FOR SELECT USING (true);
DROP POLICY IF EXISTS "Users manage own profile" ON public.profiles;
CREATE POLICY "Users manage own profile" ON public.profiles FOR ALL USING (auth.uid() = id);

DROP POLICY IF EXISTS "Public leaderboard readable" ON public.game_records;
CREATE POLICY "Public leaderboard readable" ON public.game_records FOR SELECT USING (true);
DROP POLICY IF EXISTS "Insert own valid records" ON public.game_records;
CREATE POLICY "Insert own valid records" ON public.game_records FOR INSERT WITH CHECK (
  auth.uid() = user_id AND
  NOT (game_type = 'sudoku' AND difficulty = 7 AND is_won = true AND duration_ms < 10000) AND
  (
    game_type <> 'chess' OR (
      coalesce(metadata->>'mode', 'vsAi') = 'vsAi' AND
      coalesce((metadata->>'moves')::int, 0) >= 4
    )
  )
);
DROP POLICY IF EXISTS "Delete own records" ON public.game_records;
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

-- ============================================================
-- Ranked Chess Matchmaking Queue & Anti-Cheat Settlement RPCs
-- ============================================================
CREATE TABLE IF NOT EXISTS public.chess_matchmaking_queue (
  user_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  username TEXT NOT NULL,
  avatar_url TEXT,
  chess_elo INTEGER NOT NULL DEFAULT 1000 CHECK (chess_elo BETWEEN 400 AND 3500),
  time_control TEXT NOT NULL CHECK (time_control IN ('bullet1', 'blitz3', 'blitz5', 'rapid10')),
  search_radius INTEGER,
  wait_seconds INTEGER NOT NULL DEFAULT 0,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.chess_matchmaking_queue ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Read own queue entry" ON public.chess_matchmaking_queue;
CREATE POLICY "Read own queue entry" ON public.chess_matchmaking_queue
  FOR SELECT USING (auth.uid() = user_id);

CREATE TABLE IF NOT EXISTS public.chess_matches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_code TEXT NOT NULL,
  time_control TEXT NOT NULL CHECK (time_control IN ('bullet1', 'blitz3', 'blitz5', 'rapid10')),
  white_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  black_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  white_elo_before INTEGER NOT NULL,
  black_elo_before INTEGER NOT NULL,
  white_elo_after INTEGER,
  black_elo_after INTEGER,
  winner_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  is_draw BOOLEAN NOT NULL DEFAULT false,
  move_count INTEGER NOT NULL DEFAULT 0,
  pgn TEXT,
  status TEXT NOT NULL DEFAULT 'playing' CHECK (status IN ('playing', 'finished', 'aborted')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  finished_at TIMESTAMPTZ,
  CONSTRAINT chess_matches_distinct_players CHECK (white_id <> black_id)
);

CREATE INDEX IF NOT EXISTS idx_chess_mm_queue_tc
  ON public.chess_matchmaking_queue(time_control, chess_elo, updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_chess_matches_players
  ON public.chess_matches(white_id, black_id, status, created_at DESC);

ALTER TABLE public.chess_matches ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Players read own matches" ON public.chess_matches;
CREATE POLICY "Players read own matches" ON public.chess_matches
  FOR SELECT USING (auth.uid() IN (white_id, black_id));

CREATE OR REPLACE FUNCTION public.matchmake_chess(
  p_time_control TEXT,
  p_search_radius INTEGER DEFAULT 50,
  p_wait_seconds INTEGER DEFAULT 0
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_me public.profiles%ROWTYPE;
  v_existing public.chess_matches%ROWTYPE;
  v_opp public.chess_matchmaking_queue%ROWTYPE;
  v_opp_profile public.profiles%ROWTYPE;
  v_white UUID;
  v_black UUID;
  v_white_elo INTEGER;
  v_black_elo INTEGER;
  v_room_code TEXT;
  v_match_id UUID;
  v_assigned TEXT;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF p_time_control NOT IN ('bullet1', 'blitz3', 'blitz5', 'rapid10') THEN
    RAISE EXCEPTION 'Timed control required for ranked matchmaking';
  END IF;

  PERFORM pg_advisory_xact_lock(hashtext('chess_mm_' || p_time_control));

  -- If opponent paired us moments ago, attach immediately to that match
  SELECT * INTO v_existing
  FROM public.chess_matches
  WHERE status = 'playing'
    AND time_control = p_time_control
    AND created_at >= now() - interval '20 seconds'
    AND (white_id = v_uid OR black_id = v_uid)
  ORDER BY created_at DESC
  LIMIT 1;

  IF FOUND THEN
    DELETE FROM public.chess_matchmaking_queue WHERE user_id = v_uid;
    IF v_existing.white_id = v_uid THEN
      v_assigned := 'white';
      SELECT * INTO v_opp_profile FROM public.profiles WHERE id = v_existing.black_id;
    ELSE
      v_assigned := 'black';
      SELECT * INTO v_opp_profile FROM public.profiles WHERE id = v_existing.white_id;
    END IF;
    RETURN jsonb_build_object(
      'status', 'matched',
      'match_id', v_existing.id,
      'room_code', v_existing.room_code,
      'assigned_color', v_assigned,
      'opponent_id', v_opp_profile.id,
      'opponent_username', coalesce(v_opp_profile.username, 'opponent'),
      'opponent_avatar_url', v_opp_profile.avatar_url,
      'opponent_elo', coalesce(v_opp_profile.chess_elo, 1000)
    );
  END IF;

  DELETE FROM public.chess_matchmaking_queue
  WHERE updated_at < now() - interval '20 seconds';

  SELECT * INTO v_me FROM public.profiles WHERE id = v_uid;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Profile not found';
  END IF;

  INSERT INTO public.chess_matchmaking_queue (
    user_id, username, avatar_url, chess_elo, time_control, search_radius, wait_seconds, updated_at
  )
  VALUES (
    v_uid, v_me.username, v_me.avatar_url, coalesce(v_me.chess_elo, 1000),
    p_time_control, p_search_radius, greatest(0, coalesce(p_wait_seconds, 0)), now()
  )
  ON CONFLICT (user_id) DO UPDATE SET
    username = excluded.username,
    avatar_url = excluded.avatar_url,
    chess_elo = excluded.chess_elo,
    time_control = excluded.time_control,
    search_radius = excluded.search_radius,
    wait_seconds = excluded.wait_seconds,
    updated_at = now();

  SELECT q.* INTO v_opp
  FROM public.chess_matchmaking_queue q
  WHERE q.user_id <> v_uid
    AND q.time_control = p_time_control
    AND q.updated_at >= now() - interval '20 seconds'
    AND (
      (
        (p_search_radius IS NULL OR abs(q.chess_elo - v_me.chess_elo) <= p_search_radius)
        AND
        (q.search_radius IS NULL OR abs(q.chess_elo - v_me.chess_elo) <= q.search_radius)
      )
      OR (
        p_search_radius IS NULL AND (
          q.wait_seconds >= 15 OR q.search_radius IS NULL OR abs(q.chess_elo - v_me.chess_elo) <= q.search_radius
        )
      )
      OR (
        q.search_radius IS NULL AND (
          p_wait_seconds >= 15 OR p_search_radius IS NULL OR abs(q.chess_elo - v_me.chess_elo) <= p_search_radius
        )
      )
    )
  ORDER BY abs(q.chess_elo - v_me.chess_elo) ASC, q.wait_seconds DESC, q.updated_at DESC
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('status', 'waiting');
  END IF;

  IF random() < 0.5 THEN
    v_white := v_uid;
    v_black := v_opp.user_id;
    v_white_elo := coalesce(v_me.chess_elo, 1000);
    v_black_elo := v_opp.chess_elo;
    v_assigned := 'white';
  ELSE
    v_white := v_opp.user_id;
    v_black := v_uid;
    v_white_elo := v_opp.chess_elo;
    v_black_elo := coalesce(v_me.chess_elo, 1000);
    v_assigned := 'black';
  END IF;

  v_room_code := upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8));

  INSERT INTO public.chess_matches (
    room_code, time_control, white_id, black_id, white_elo_before, black_elo_before, status
  )
  VALUES (
    v_room_code, p_time_control, v_white, v_black, v_white_elo, v_black_elo, 'playing'
  )
  RETURNING id INTO v_match_id;

  DELETE FROM public.chess_matchmaking_queue WHERE user_id IN (v_uid, v_opp.user_id);

  RETURN jsonb_build_object(
    'status', 'matched',
    'match_id', v_match_id,
    'room_code', v_room_code,
    'assigned_color', v_assigned,
    'opponent_id', v_opp.user_id,
    'opponent_username', v_opp.username,
    'opponent_avatar_url', v_opp.avatar_url,
    'opponent_elo', v_opp.chess_elo
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.cancel_chess_matchmaking()
RETURNS void
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  DELETE FROM public.chess_matchmaking_queue WHERE user_id = auth.uid();
$$;

CREATE OR REPLACE FUNCTION public.finish_ranked_chess_match(
  p_match_id UUID,
  p_winner_colour INTEGER,
  p_is_draw BOOLEAN,
  p_move_count INTEGER,
  p_pgn TEXT DEFAULT ''
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_m public.chess_matches%ROWTYPE;
  v_winner_id UUID;
  v_expected_w DOUBLE PRECISION;
  v_actual_w DOUBLE PRECISION;
  v_new_w INTEGER;
  v_new_b INTEGER;
  v_caller_new INTEGER;
  v_caller_before INTEGER;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  SELECT * INTO v_m
  FROM public.chess_matches
  WHERE id = p_match_id
  FOR UPDATE;

  IF NOT FOUND OR (v_uid <> v_m.white_id AND v_uid <> v_m.black_id) THEN
    RAISE EXCEPTION 'Match not found or unauthorized';
  END IF;

  -- Idempotent settlement when the second player submits the finished board
  IF v_m.status IN ('finished', 'aborted') THEN
    IF v_uid = v_m.white_id THEN
      v_caller_before := v_m.white_elo_before;
      v_caller_new := coalesce(v_m.white_elo_after, v_m.white_elo_before);
    ELSE
      v_caller_before := v_m.black_elo_before;
      v_caller_new := coalesce(v_m.black_elo_after, v_m.black_elo_before);
    END IF;
    RETURN jsonb_build_object(
      'status', v_m.status,
      'new_elo', v_caller_new,
      'elo_delta', v_caller_new - v_caller_before
    );
  END IF;

  -- Fair Play: games ended before 4 half-moves cannot alter ELO
  IF coalesce(p_move_count, 0) < 4 THEN
    UPDATE public.chess_matches
    SET status = 'aborted',
        move_count = greatest(0, coalesce(p_move_count, 0)),
        pgn = p_pgn,
        white_elo_after = v_m.white_elo_before,
        black_elo_after = v_m.black_elo_before,
        finished_at = now()
    WHERE id = p_match_id;

    v_caller_before := CASE WHEN v_uid = v_m.white_id THEN v_m.white_elo_before ELSE v_m.black_elo_before END;
    RETURN jsonb_build_object(
      'status', 'aborted',
      'new_elo', v_caller_before,
      'elo_delta', 0
    );
  END IF;

  v_expected_w := 1.0 / (1.0 + power(10.0, (v_m.black_elo_before - v_m.white_elo_before) / 400.0));
  IF coalesce(p_is_draw, false) THEN
    v_actual_w := 0.5;
    v_winner_id := NULL;
  ELSIF p_winner_colour = 0 THEN
    v_actual_w := 1.0;
    v_winner_id := v_m.white_id;
  ELSIF p_winner_colour = 1 THEN
    v_actual_w := 0.0;
    v_winner_id := v_m.black_id;
  ELSE
    RAISE EXCEPTION 'Invalid winner colour';
  END IF;

  v_new_w := least(3500, greatest(400, round(v_m.white_elo_before + 32.0 * (v_actual_w - v_expected_w))::int));
  v_new_b := least(3500, greatest(400, round(v_m.black_elo_before + 32.0 * ((1.0 - v_actual_w) - (1.0 - v_expected_w)))::int));

  UPDATE public.profiles SET chess_elo = v_new_w WHERE id = v_m.white_id;
  UPDATE public.profiles SET chess_elo = v_new_b WHERE id = v_m.black_id;

  UPDATE public.chess_matches
  SET status = 'finished',
      winner_id = v_winner_id,
      is_draw = coalesce(p_is_draw, false),
      move_count = coalesce(p_move_count, 0),
      pgn = p_pgn,
      white_elo_after = v_new_w,
      black_elo_after = v_new_b,
      finished_at = now()
  WHERE id = p_match_id;

  IF v_uid = v_m.white_id THEN
    v_caller_before := v_m.white_elo_before;
    v_caller_new := v_new_w;
  ELSE
    v_caller_before := v_m.black_elo_before;
    v_caller_new := v_new_b;
  END IF;

  RETURN jsonb_build_object(
    'status', 'finished',
    'new_elo', v_caller_new,
    'elo_delta', v_caller_new - v_caller_before
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.matchmake_chess(TEXT, INTEGER, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION public.cancel_chess_matchmaking() TO authenticated;
GRANT EXECUTE ON FUNCTION public.finish_ranked_chess_match(UUID, INTEGER, BOOLEAN, INTEGER, TEXT) TO authenticated;

-- ============================================================
-- 7. Feedback System (Player Private + Admin Moderation Inbox)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.feedbacks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL CONSTRAINT feedbacks_user_id_fkey REFERENCES public.profiles(id) ON DELETE CASCADE,
  message TEXT NOT NULL CHECK (char_length(trim(message)) BETWEEN 3 AND 1000),
  app_version TEXT NOT NULL DEFAULT '0.0.0',
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  admin_reply TEXT CHECK (admin_reply IS NULL OR char_length(trim(admin_reply)) <= 500),
  reviewed_by UUID CONSTRAINT feedbacks_reviewed_by_fkey REFERENCES public.profiles(id) ON DELETE SET NULL,
  reviewed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_feedbacks_created
  ON public.feedbacks (created_at DESC, id ASC);
CREATE INDEX IF NOT EXISTS idx_feedbacks_user_status
  ON public.feedbacks (user_id, status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_feedbacks_reviewed_by
  ON public.feedbacks (reviewed_by);

CREATE OR REPLACE FUNCTION public.enforce_feedback_insert_limit()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_pending_count INTEGER;
BEGIN
  -- Kunci baris profile user agar tidak bisa bypass batas 5 dengan request paralel
  PERFORM 1 FROM public.profiles WHERE id = NEW.user_id FOR UPDATE;

  SELECT COUNT(*) INTO v_pending_count
  FROM public.feedbacks
  WHERE user_id = NEW.user_id
    AND status = 'pending';

  IF v_pending_count >= 5 THEN
    RAISE EXCEPTION 'Maximum 5 pending feedback items per user';
  END IF;

  NEW.status := 'pending';
  NEW.admin_reply := NULL;
  NEW.reviewed_by := NULL;
  NEW.reviewed_at := NULL;
  NEW.created_at := NOW();
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_feedback_insert_limit ON public.feedbacks;
CREATE TRIGGER trg_feedback_insert_limit
  BEFORE INSERT ON public.feedbacks
  FOR EACH ROW
  EXECUTE FUNCTION public.enforce_feedback_insert_limit();

CREATE OR REPLACE FUNCTION public.protect_feedback_update_fields()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.id IS DISTINCT FROM OLD.id OR
     NEW.user_id IS DISTINCT FROM OLD.user_id OR
     NEW.app_version IS DISTINCT FROM OLD.app_version OR
     NEW.created_at IS DISTINCT FROM OLD.created_at THEN
    RAISE EXCEPTION 'Immutable feedback metadata cannot be changed';
  END IF;

  -- Admin review (1x saat pending -> approved/rejected + opsional 1 pesan)
  IF public.is_admin() AND auth.uid() <> OLD.user_id OR
     (public.is_admin() AND NEW.status IN ('approved', 'rejected') AND OLD.status = 'pending') THEN
    IF OLD.status <> 'pending' THEN
      RAISE EXCEPTION 'Feedback has already been reviewed';
    END IF;
    IF NEW.status NOT IN ('approved', 'rejected') THEN
      RAISE EXCEPTION 'Admin decision must be approved or rejected';
    END IF;
    NEW.message := OLD.message;
    NEW.reviewed_by := auth.uid();
    NEW.reviewed_at := NOW();
    NEW.updated_at := NOW();
    RETURN NEW;
  END IF;

  -- Player edit sendiri (< 6 jam & belum ditinjau admin)
  IF auth.uid() = OLD.user_id THEN
    IF OLD.status <> 'pending' THEN
      RAISE EXCEPTION 'Reviewed feedback cannot be edited';
    END IF;
    IF NOW() - OLD.created_at >= interval '6 hours' THEN
      RAISE EXCEPTION 'Edit window (6 hours) has expired';
    END IF;
    NEW.status := OLD.status;
    NEW.admin_reply := OLD.admin_reply;
    NEW.reviewed_by := OLD.reviewed_by;
    NEW.reviewed_at := OLD.reviewed_at;
    NEW.updated_at := NOW();
    RETURN NEW;
  END IF;

  RAISE EXCEPTION 'Unauthorized feedback update';
END;
$$;

DROP TRIGGER IF EXISTS trg_feedback_update_guard ON public.feedbacks;
CREATE TRIGGER trg_feedback_update_guard
  BEFORE UPDATE ON public.feedbacks
  FOR EACH ROW
  EXECUTE FUNCTION public.protect_feedback_update_fields();

REVOKE ALL ON FUNCTION public.enforce_feedback_insert_limit() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.protect_feedback_update_fields() FROM PUBLIC, anon, authenticated;

ALTER TABLE public.feedbacks ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.feedbacks FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.feedbacks TO authenticated;

DROP POLICY IF EXISTS "Read own or admin feedbacks" ON public.feedbacks;
CREATE POLICY "Read own or admin feedbacks" ON public.feedbacks
  FOR SELECT TO authenticated
  USING (
    (((SELECT auth.uid()) = user_id) OR public.is_admin()) AND
    (reviewed_at IS NULL OR reviewed_at > NOW() - interval '3 days')
  );

DROP POLICY IF EXISTS "Insert own feedback" ON public.feedbacks;
CREATE POLICY "Insert own feedback" ON public.feedbacks
  FOR INSERT TO authenticated
  WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Update own within 6h or admin review" ON public.feedbacks;
CREATE POLICY "Update own within 6h or admin review" ON public.feedbacks
  FOR UPDATE TO authenticated
  USING (
    ((SELECT auth.uid()) = user_id AND status = 'pending' AND NOW() - created_at < interval '6 hours') OR
    (public.is_admin() AND status = 'pending')
  )
  WITH CHECK (
    ((SELECT auth.uid()) = user_id AND status = 'pending') OR
    (public.is_admin() AND status IN ('approved', 'rejected'))
  );

DROP POLICY IF EXISTS "Delete own feedback anytime" ON public.feedbacks;
CREATE POLICY "Delete own feedback anytime" ON public.feedbacks
  FOR DELETE TO authenticated
  USING ((SELECT auth.uid()) = user_id);

-- Hapus fisik feedback yang sudah dicentang / ditolak > 3 hari (berjalan di semua paket Supabase, termasuk Free)
CREATE OR REPLACE FUNCTION public.cleanup_expired_feedbacks()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_deleted INTEGER;
BEGIN
  IF auth.uid() IS NULL AND current_user NOT IN ('postgres', 'supabase_admin', 'service_role') THEN
    RETURN 0;
  END IF;
  DELETE FROM public.feedbacks
  WHERE reviewed_at IS NOT NULL
    AND reviewed_at <= NOW() - interval '3 days';
  GET DIAGNOSTICS v_deleted = ROW_COUNT;
  RETURN v_deleted;
END;
$$;

REVOKE ALL ON FUNCTION public.cleanup_expired_feedbacks() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.cleanup_expired_feedbacks() TO authenticated;

-- Opsional jika pg_cron diaktifkan di Dashboard -> Database -> Extensions:
-- SELECT cron.schedule('cleanup-expired-feedbacks', '0 * * * *', $$SELECT public.cleanup_expired_feedbacks();$$);
```

3. Klik **Run** (atau `Cmd/Ctrl + Enter`). Pastikan muncul pesan sukses (`Success. No rows returned` atau query berhasil tanpa error). Karena memakai `IF NOT EXISTS` dan `DROP POLICY IF EXISTS`, SQL ini **aman dijalankan langsung pada project Supabase yang sudah berjalan tanpa menghapus tabel lama**.
4. Cek hasil di sidebar **Table Editor**: tabel `profiles` (termasuk kolom `role` dan `account_data`), `game_records`, `feedbacks`, `chess_matchmaking_queue`, dan `chess_matches` sudah muncul. Cek di **Storage**: bucket `avatars` berstatus **Public**.

---

## Langkah 3 — Atur Supabase Authentication (PENTING)

Zetzy memakai sistem akun **username-only tanpa verifikasi email** (secara internal mengubah `username` menjadi `username@arcade.local` di `ValidationRules.dummyEmailFor`). Karena domain `@arcade.local` tidak bisa menerima email sungguhan, **konfirmasi email wajib dimatikan**:

1. Buka **Authentication → Sign In / Providers** (atau **Providers → Email**).
2. Pastikan **Enable Email provider** = **ON**.
3. Pastikan **Confirm email** = **OFF** *(wajib dimatikan agar user yang baru daftar langsung mendapatkan session aktif tanpa klik link email)*.
4. Klik **Save**.

> **Catatan keamanan:** Zetzy menerapkan Single Active Session (`signOut(scope: SignOutScope.others)`) setiap kali login/register, sesuai PRD. Password reset tanpa email menggunakan RPC `reset_password_with_recovery` dengan recovery phrase yang di-hash SHA-256.

> **Cara Mengubah Role User (`player` ↔ `admin`) lewat Supabase Table Editor:**
> Untuk keamanan, aplikasi tidak menyediakan tombol ubah role di sisi client (kolom `role` dilindungi trigger database dari request API client). Untuk menjadikan sebuah akun sebagai **Admin**:
> 1. Buka Supabase Dashboard → **Table Editor** → pilih tabel **`profiles`**.
> 2. Cari baris user yang diinginkan (berdasarkan `username`).
> 3. Klik dua kali sel pada kolom **`role`**, ganti nilainya dari `player` menjadi **`admin`** (huruf kecil), lalu klik **Save**.
> 4. Buka ulang / refresh aplikasi Zetzy dengan akun tersebut — badge **ADMIN** akan muncul di Profile dan halaman **Feedback** akan menampilkan tab **Admin Inbox**.

---

## Langkah 4 — Ambil Project URL & API Key

1. Buka **Project Settings** (ikon roda gigi di kiri bawah) → **API** (atau **Data API** / **API Keys**).
2. Salin dua nilai ini:
   - **Project URL**: contoh `https://abcdefghijklmno.supabase.co` *(hanya root URL project, JANGAN tambahkan `/rest/v1/` di belakangnya)*
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
      "program": "lib/main.dart",
      "cwd": "${workspaceFolder}",
      "toolArgs": [
        "--dart-define-from-file=supabase.json"
      ]
    }
  ]
}
```

> `.vscode/settings.json` juga sudah dikonfigurasi dengan `dart.flutterRunAdditionalArgs` (`--dart-define-from-file=supabase.json`) agar tombol **Run Without Debugging** / CodeLens di VS Code/Antigravity meneruskan kredensial Supabase ke semua platform (Android, iOS, Web, Windows, Linux, macOS).
> Untuk Android, `android/app/build.gradle.kts` otomatis membaca `supabase.json` saat build jika flag `--dart-define` belum diteruskan. Untuk Desktop (Windows/Linux) mode Debug/Profile, aplikasi juga memiliki fallback runtime ke `supabase.json`. Jika ingin menjalankan mode offline murni tanpa `supabase.json`, cukup isi `{}` pada `supabase.json` atau hapus flag tersebut dari `.vscode/settings.json`.

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
