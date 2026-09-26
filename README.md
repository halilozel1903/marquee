# Marquee

Marquee is a native Apple TV catalog for movies and series. It is a SwiftUI app for tvOS 17 and later, laid out for a television: large type, poster art, and focus-driven navigation. It is an independent project and is not part of the Apple TV brand.

The app reads Apple's public store catalog over HTTPS. There is no API key, account, or backend.

## Features

- **Home** shows the current top movies and top series as horizontal poster rails.
- **Movies** and **Series** show those same charts as grids.
- **Search** queries the catalog as you type and returns movies and series together.
- **Detail** shows artwork, title, credit, genre, release date, and synopsis, with a **View in the Store** action.
- Every screen that loads data has a loading state, an empty state, and an error state with **Try Again**.

The interface is dark, built for a 10-foot distance, and uses the tvOS focus engine. Tabs are Home, Movies, Series, and Search.

## Requirements

- macOS with Xcode 15 or later
- The tvOS 17 SDK
- An Apple TV simulator on tvOS 17 or later
- A network connection from the simulator to Apple's catalog

## Run

1. Open `Marquee.xcodeproj` in Xcode.
2. Select the **Marquee** scheme.
3. Choose an Apple TV simulator as the run destination.
4. Press Run.

The simulator target is configured with `CODE_SIGN_IDENTITY = -`, so a development team is not required. Installing on a physical Apple TV requires your own team under Signing & Capabilities.

## Project layout

```
Marquee.xcodeproj          tvOS app target and shared scheme
Marquee/
  MarqueeApp.swift         App entry
  Models/                  Catalog titles and detail records
  Catalog/                 Live store client and payload decoding
  Screens/                 Home, grids, search, and detail
  Components/              Posters, rails, headers, and status views
  Theme/                   Color, type, and screen metrics
```

## Catalog

Charts and search use the Turkey store (`country=tr`). The interface itself is English.

Home, Movies, and Series request two chart feeds at once and show the first list that returns titles:

| Chart | Sources |
| --- | --- |
| Top movies | [Apple Marketing Tools](https://rss.applemarketingtools.com/api/v2/tr/movies/top-movies/40/movies.json), then the [iTunes top movies RSS](https://itunes.apple.com/tr/rss/topmovies/limit=40/json) |
| Top series | [Apple Marketing Tools](https://rss.applemarketingtools.com/api/v2/tr/tv-shows/top-tv-seasons/40/tv-seasons.json), then the [iTunes top TV seasons RSS](https://itunes.apple.com/tr/rss/toptvseasons/limit=40/json) |

The marketing-tools movie and TV routes are unreliable, so the iTunes RSS charts are requested in parallel. A hung host does not block the list. If a feed answers with an empty chart, the screen stays empty.

Search calls the [iTunes Search API](https://itunes.apple.com/search) with `country=tr`, once for movies (`media=movie`, `entity=movie`) and once for series (`media=tvShow`, `entity=tvSeason`). If a filtered query comes back empty, Marquee queries the same endpoint without a media filter and keeps feature films and TV seasons whose titles match. Results update after two characters, with a short debounce.

The detail screen calls `https://itunes.apple.com/lookup?id=ID&country=tr`. **View in the Store** opens `trackViewUrl` for a movie and `collectionViewUrl` for a season. If lookup fails, the synopsis already present on the chart title stays on screen.
