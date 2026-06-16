# KickOff — Project Guide

A multi-league football app built with Flutter. Originally World-Cup-only, now a
"proper" football app covering the **top 7 competitions** via the
football-data.org REST API, with favourites, top scorers, team pages, theming,
search, onboarding, and a Following hub.

This file is the entry point for understanding the project. Read it first, then
dive into the relevant feature folder.

---

## Tech stack & SDK

- **Flutter** (Material 3), **Dart `^3.11.5`** (pubspec constraint). Dev machines
  run Dart 3.12.x.
- **Riverpod 3** (`flutter_riverpod`) — `Notifier`, `AsyncNotifier`,
  `FutureProvider`, `FutureProvider.family`, `Provider`, `ProviderScope` overrides.
- **google_fonts** (Outfit headings + Inter body), **intl** (dates),
  **shared_preferences** (persistence), **http** (API), **flutter_svg** (crests),
  **flutter_dotenv** (API key), **scrollable_positioned_list** (scroll-to-today).
- Target platform during development: **Windows desktop** (also builds for
  Android/iOS/web).

## Commands

```bash
flutter pub get
flutter analyze --no-pub          # must be clean before considering work done
flutter build windows --debug     # primary build check on the dev machine
flutter run -d windows            # run the app
```

Workflow rule we follow: after any change, run `flutter analyze` then
`flutter build windows --debug` and confirm both pass.

## Setup / two-PC workflow

- The football-data.org API key lives in a **git-ignored `.env`** file at the repo
  root as `FOOTBALL_API_KEY=<key>`. Get a free key at
  https://www.football-data.org/client/register.
- The project is developed across **two machines (home + office)**. `.env` is not
  committed, so **the key must be re-added on each machine** (copy it from the
  other PC or the football-data.org dashboard). `.env.example` shows the format.
- Without a key, the app falls back to **bundled World Cup sample data only**
  (`assets/data/sample_matches.json`); other leagues need the key.
- The key can also be supplied at build time:
  `flutter run --dart-define=FOOTBALL_API_KEY=...` (takes precedence over `.env`).

## ⚠️ Free-tier API constraints (verified live — design around these)

The football-data.org **free tier** is limited. These were confirmed against the
real key and shape what's buildable:

- **Rate limit: 10 requests/minute.** 429s are expected — all network paths show a
  friendly message (see `lib/src/core/api/api_error.dart`, `friendlyError()`), and
  caching is aggressive.
- **`/matches/{id}` returns NO goals / bookings / substitutions** (all null) — a
  play-by-play event timeline is **impossible** without a paid plan. Only metadata
  (matchday, competition, referees, score, result type) is available.
- **`/teams/{id}` and `/teams/{id}/matches` are restricted** ("not within your
  permissions") — so **no squad/coach/venue** and **no cross-competition team
  feed**. A team's data can only be assembled from the **already-loaded
  competition** (its matches + standings row).
- **Works on free tier:** `/competitions/{code}/matches`, `/competitions/{code}/standings`,
  `/competitions/{code}/scorers`, `/matches/{id}` (metadata only), `/competitions/{code}`.

The 7 competitions (`Competition.all` in
`lib/src/features/competitions/data/competition.dart`):
Premier League (`PL`), La Liga (`PD`), Serie A (`SA`), Bundesliga (`BL1`),
Ligue 1 (`FL1`), Champions League (`CL`, cup), World Cup (`WC`, cup, no emblem →
icon fallback). `hasKnockout => type == cup`.

---

## Architecture

Feature-first under `lib/src/`:

```
lib/
  main.dart                      # preloads prefs, injects via ProviderScope overrides
  src/
    app.dart                     # MaterialApp, theme, onboarding-vs-home gate
    home_shell.dart              # bottom nav: Matches/Standings/Scorers/[Bracket]
    core/
      api/
        api_config.dart          # reads FOOTBALL_API_KEY (.env or --dart-define)
        football_api_client.dart # thin v4 client; 429 + error handling
        api_error.dart           # friendlyError(Object) -> human message
      theme/
        app_theme.dart           # dark + light themes (teal/black), google_fonts
        theme_mode_provider.dart # persisted ThemeMode
      widgets/
        skeleton.dart            # Shimmer + SkeletonBox loaders
        section_header.dart      # HeaderGradient, BrandTitle, relativeTimeLabel
        football_loader.dart     # legacy spinner (mostly replaced by skeletons)
    features/
      competitions/              # league model, selection, switcher, shared app bar
      matches/                   # fixtures/results, match detail, match cards
      standings/                 # league/group tables
      scorers/                   # top scorers
      knockout/                  # cup bracket
      team/                      # scoped team page
      favourites/                # followed teams (league-aware)
      following/                 # Following hub (grouped by league)
      search/                    # app-wide team search
      settings/                  # appearance + followed-teams management
      onboarding/                # first-run flow
```

Each feature typically has `data/` (models, repositories), `application/`
(providers), and `presentation/` (screens, widgets).

## Key conventions & patterns

- **Boot preload pattern.** Anything that must be correct on the first frame is
  loaded in `main()` and injected via a `bootstrap*Provider` override, so the
  notifier seeds it **synchronously** in `build()` (no async state mutation during
  build — which previously caused a "setState during build" crash). Used for:
  - selected league — `bootstrapCompetitionProvider` / `loadSavedCompetition()`
  - theme mode — `bootstrapThemeModeProvider` / `loadThemeMode()`
  - onboarding flag — `bootstrapOnboardingDoneProvider` / `loadOnboardingDone()`
  - favourites — `bootstrapFavouritesProvider` / `loadFavourites()`
- **Smart caching (stale-while-revalidate).** Raw API responses are cached per
  competition in `shared_preferences` via `FootballCache` (keys like
  `matches_PL`, `standings_CL`, `scorers_PD`, `match_<id>`). Cache-first reads;
  background revalidate when stale; serve stale on network failure. Live matches
  use a shorter TTL.
- **Per-league family providers.** `competitionMatchesProvider(code)` and
  `standingsForProvider(code)` fetch a *specific* league's data so screens (e.g.
  the team page opened from search) don't change the user's selected league.
- **Errors:** never show raw exceptions — wrap with `friendlyError()`.
- **Loading:** use `Shimmer`/`SkeletonBox` skeletons, not bare spinners.
- **Crests/emblems:** `TeamCrest` (SVG+PNG with code fallback),
  `CompetitionEmblem` (PNG with trophy-icon fallback).

## Navigation & UX model (current)

- **Bottom nav:** Matches · Standings · Scorers · Bracket (Bracket only for cups).
  **No Leagues tab.**
- **Shared top bar** = `LeagueAppBar`
  (`features/competitions/presentation/league_app_bar.dart`):
  - **Tappable league switcher** on the left (`LeagueSwitcherTitle` → bottom-sheet
    of all 7 leagues via `showLeagueSwitcher`).
  - Right-side actions: **🔍 Search · ⭐ Following · ⚙ Settings**.
- **League persistence = "remember last viewed".** There is ONE persisted current
  league (`selectedCompetitionProvider`; `select()` persists and the app reopens
  to it). The old separate "default league + star" concept was removed.
- **Following is global by team id**, but each favourite is **tagged with the
  league it was followed from** (`FavouriteTeam.competitionCode`) to power the
  per-league grouping in the Following hub and Settings.
- **Easy follow:** one-tap ⭐ on global-search results; Following hub has an "add"
  button + empty-state CTA into search; plus Follow buttons on match detail and
  team pages.

## Feature checklist (all implemented)

1. Multi-league (7 competitions) with smart caching.
2. Matches: day-grouped list, scroll-to-today, status filter (All/Fixtures/
   Results/Live/★ favourites), live pulse, match cards.
3. Match detail: scoreline + enriched facts (matchday, competition, referee,
   result type, last-updated) from `/matches/{id}`.
4. Standings: league tables / cup groups / UCL league phase, qualifying
   highlights, followed-team highlight.
5. Top scorers (goals/assists/penalties, medal ranks).
6. Knockout bracket (cups only).
7. Favourite teams (league-aware) + Following hub grouped by league (next/last
   match from cache).
8. Scoped team page (results/fixtures + standings row for its league).
9. App-wide team search across cached leagues, with inline follow.
10. Theming: dark/light/system toggle (Settings).
11. First-run onboarding (pick league → optionally follow teams), skippable.
12. Friendly error/rate-limit UX, skeleton loaders, premium polish.

## Gotchas / notes

- **World Cup 2026** fixtures may not be published yet → that league shows a
  friendly "fixtures not published yet" empty state. Scorers will be empty too.
  This is expected, not a bug.
- The Following hub and global search only show data for leagues **already
  cached** (opened at least once) — a free-tier limitation, surfaced in the UI.
- `flutter analyze` should report **no issues**; keep it that way.
- Don't reintroduce a separate "default league" or a second in-screen search —
  these were intentionally consolidated to reduce clutter.
