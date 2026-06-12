<h1 align="center">KickOff ⚽</h1>

<p align="center">
  <b>A FIFA World Cup 2026 fixtures, results & standings app — built with Flutter.</b>
</p>

<p align="center">
  <img alt="Flutter"  src="https://img.shields.io/badge/Flutter-3.41-02569B?logo=flutter&logoColor=white">
  <img alt="Dart"     src="https://img.shields.io/badge/Dart-3.11-0175C2?logo=dart&logoColor=white">
  <img alt="Riverpod" src="https://img.shields.io/badge/State-Riverpod%203-4c51bf">
  <img alt="Platforms" src="https://img.shields.io/badge/Platforms-Android%20%C2%B7%20iOS%20%C2%B7%20Web%20%C2%B7%20Windows-444">
</p>

---

KickOff shows the full World Cup schedule, live scores, results and group
standings. Live data comes from [football-data.org](https://www.football-data.org),
with **smart on-device caching** so the app is fast, works offline, and stays
well within the free API tier.

## ✨ Features

- **Fixtures, Results & Live** matches with a segmented filter
- **Match preview / detail** screen with crests, scoreline and key facts
- **Group standings** computed from results — points, GD, and top-2 highlighted
- **Smart caching** (free-tier friendly):
  - Loads instantly from disk on launch
  - Refreshes in the background only when data is stale
  - Pull-to-refresh forces a fresh fetch; everything else is served from cache
  - Falls back to cached data when offline or rate-limited
- **Polished UI** — black & teal theme, animated football loader, team flags
  (SVG + PNG)
- Runs **out of the box** with bundled sample data if no API key is set

## 📸 Screenshots

> _Add screenshots here, e.g._
> `![Matches](docs/matches.png)` · `![Standings](docs/standings.png)`

## 🛠️ Tech stack

| Concern        | Choice |
| -------------- | ------ |
| Framework      | Flutter (Material 3) |
| State          | [Riverpod 3](https://riverpod.dev) (`AsyncNotifier`, `Notifier`) |
| Networking     | `http` → football-data.org v4 |
| Local cache    | `shared_preferences` |
| Config/secrets | `flutter_dotenv` (`.env`) |
| Images         | `flutter_svg` for crests/flags |

## 🚀 Getting started

### 1. Prerequisites
- Flutter SDK (3.41+) — run `flutter doctor` to verify your setup.

### 2. Get a free API key
Register at <https://www.football-data.org/client/register> (takes ~1 minute).
The free tier includes the World Cup competition.

### 3. Configure your key
The key is read from a git-ignored `.env` file, so it is **never committed**.

```bash
cp .env.example .env
# then open .env and set your key:
# FOOTBALL_API_KEY=your_key_here
```

> Prefer not to use a file? Pass it at run time instead:
> ```bash
> flutter run --dart-define=FOOTBALL_API_KEY=your_key_here
> ```
>
> No key at all? The app still runs using bundled sample fixtures.

### 4. Run
```bash
flutter pub get
flutter run            # choose a device, or:
flutter run -d windows # Windows desktop
flutter run -d chrome  # web
```

## 🗂️ Project structure

```
lib/
├─ main.dart                     # loads .env, boots ProviderScope
└─ src/
   ├─ app.dart                   # MaterialApp, theme, scroll behavior
   ├─ home_shell.dart            # bottom nav (Matches | Standings)
   ├─ core/
   │  ├─ api/                    # ApiConfig + football-data.org client
   │  ├─ theme/                  # black & teal AppTheme
   │  └─ widgets/                # football loader, brand/header widgets
   └─ features/
      ├─ matches/                # models, repository, cache, providers, UI
      └─ standings/              # standings computation + UI
```

## 🧠 How caching works

`matchesProvider` is an `AsyncNotifier` that:

1. On launch, shows the **disk cache instantly**, then revalidates in the
   background **only if it's stale** (TTL: 1 min while a match is live, 5 min
   otherwise).
2. On **pull-to-refresh**, always calls the API and updates the cache.
3. On tab/filter changes, reuses the in-memory value — **no API calls**.
4. On failure (offline / rate-limited), keeps showing cached data.

The raw API response is cached via `shared_preferences`; standings are derived
client-side, so they cost **zero** extra API calls.

## 🔑 Security note

`.env` is listed in `.gitignore`, so your API key stays out of version control.
Only `.env.example` (a placeholder) is committed. If you ever expose a key,
revoke/regenerate it from the football-data.org dashboard.

## 🙏 Credits

- Match data: [football-data.org](https://www.football-data.org)
- Not affiliated with or endorsed by FIFA. Team crests/flags belong to their
  respective owners.

## 📄 License

Released under the MIT License — see [`LICENSE`](LICENSE) (add one if you intend
to open-source this).
