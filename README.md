# AniShelf

An anime discovery app and personal anime list for Flutter, powered by the
[Jikan API](https://jikan.moe) (an unofficial MyAnimeList API). It uses
MyAnimeList's light and dark color schemes, with dark mode as the default.

## Features

- **Discover**: featured banner, then Trending Now, This Season, Upcoming,
  Most Popular and All-Time Top carousels, each with an infinite
  "See all" grid.
- **Search**: debounced search, recent searches, and filters for genre,
  type, status, season/year, age rating and minimum score, plus sorting by
  best match, score, popularity, favorites, newest, oldest or title.
- **Details**: score, rank, popularity, members, episodes, air dates,
  season, studios, producers, synopsis, background, characters with voice
  actors, and recommendations.
- **My List**: Watching / Completed / On Hold / Dropped / Plan to Watch,
  with episode progress you can update from the list.
- **Favorites**: favorite any anime; favorites are independent of My List.
- **Offline**: My List and Favorites are stored on the device. The last
  response for each screen is saved to disk and shown when you're offline
  or MyAnimeList is down, and posters are cached.

## Running

```bash
flutter pub get
flutter run
```

Tests and static analysis:

```bash
flutter analyze
flutter test
```

### Using a self-hosted Jikan instance

By default the app uses `https://api.jikan.moe/v4`. That public API allows
3 requests per second and 60 per minute, and the app stays under both
limits. To use your own instance instead:

```bash
# Desktop / iOS simulator
flutter run --dart-define=JIKAN_BASE_URL=http://localhost:8080/v4

# Android emulator (10.0.2.2 is the host machine)
flutter run --dart-define=JIKAN_BASE_URL=http://10.0.2.2:8080/v4
```

With a custom URL the app sends up to 10 requests per second. It keeps
that cap because a self-hosted Jikan scrapes MyAnimeList on cache misses,
and MyAnimeList may block an IP that requests too fast. Plain-HTTP URLs
work in Android debug builds only.

A self-hosted Jikan needs MongoDB, Redis and Typesense next to it (see
the [jikan-rest container guide](https://github.com/jikan-me/jikan-rest/blob/master/container_usage.md)).
From a jikan-rest checkout, with its `*.txt` secret files in place:

```bash
docker compose -p jikan-api up -d     # start
docker compose -p jikan-api down      # stop
```

Details, characters and recommendations are scraped from MyAnimeList on
first request and then stored. Top, seasonal, genre and search lists only
contain anime the instance has already seen, until the indexers run
(`./container-setup.sh execute-indexers`, which takes days).

## Architecture

```
lib/
  app.dart, main.dart       App root and startup
  core/
    constants/  di/         Configuration; dependency scope (InheritedWidget)
    errors/                 Sealed AppException hierarchy
    navigation/             Adaptive shell (bottom bar / rail), router
    network/                Jikan client: caching, de-duplication, rate
                            limiting, retries, offline fallback
    settings/ state/        Theme setting; paged-list and async state
    storage/ theme/ utils/  Key-value storage, MAL colors, helpers
  features/
    home/ search/ anime_details/ library/ favorites/
      data/ models/ repositories/ controllers/ screens/ widgets/
  shared/
    models/                 Jikan models (null-tolerant parsing)
    widgets/                Cards, posters, grids, skeletons, states
```

State is managed with `ChangeNotifier` controllers and `ListenableBuilder`;
no state-management package is used.

### Dependencies

| Package | Why |
| --- | --- |
| `http` | Cross-platform HTTP client with `MockClient` for tests |
| `shared_preferences` | Small local key-value storage (list, favorites, settings) |
| `cached_network_image` | Disk-cached posters, so saved anime show offline |
| `path_provider` | Cache directory for saved API responses |

## Known limitations

- Season/year filtering uses Jikan's seasonal endpoint. The other filters
  are applied on the device there, so sorting covers only the results
  loaded so far.
- Jikan doesn't know the episode count of many ongoing shows; progress for
  those shows has no upper limit.
- No account sync: My List and Favorites live on this device only.
