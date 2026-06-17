-- 포모도로 세션 기록 (pomodoro 스키마) + 로그인(Auth) 연동
-- Supabase 대시보드 > SQL Editor 에 붙여넣고 실행하세요.

-- 1. pomodoro 스키마
create schema if not exists pomodoro;

-- 2. 테이블
create table if not exists pomodoro.sessions (
  id          uuid primary key default gen_random_uuid(),
  mode        text not null default 'focus',          -- 'focus' | 'break'
  duration_seconds integer not null,                  -- 세션 길이(초)
  completed_at timestamptz not null default now()
);

create index if not exists sessions_completed_at_idx
  on pomodoro.sessions (completed_at desc);

-- 3. 권한 (public 외 스키마는 직접 부여 필요)
grant usage on schema pomodoro to anon, authenticated;
grant all on all tables in schema pomodoro to anon, authenticated;
alter default privileges in schema pomodoro
  grant all on tables to anon, authenticated;

-- ── 로그인(Auth) 연동 ────────────────────────────────────────────
-- 4. 사용자 식별 컬럼 (insert 시 로그인 사용자가 자동으로 채워짐)
alter table pomodoro.sessions
  add column if not exists user_id uuid default auth.uid() references auth.users(id);

-- 5. RLS 켜고 "본인 기록만" 정책 적용
alter table pomodoro.sessions enable row level security;

drop policy if exists "own select" on pomodoro.sessions;
drop policy if exists "own insert" on pomodoro.sessions;

create policy "own select" on pomodoro.sessions
  for select to authenticated using (user_id = auth.uid());

create policy "own insert" on pomodoro.sessions
  for insert to authenticated with check (user_id = auth.uid());

-- ★ 대시보드 추가 설정:
--   - Project Settings > API > Exposed schemas 에 'pomodoro' 포함 (이미 완료)
--   - (선택) Authentication > Providers > Email > "Confirm email" 끄면
--     가입 즉시 로그인되어 테스트가 편합니다.
