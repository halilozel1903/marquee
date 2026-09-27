# Marquee

A native Apple TV catalog for movies and series. SwiftUI, tvOS 17+, no API key.

Marquee is built for a television: poster rails, a four-tab bar, and a focus highlight you can drive with the remote. It reads Apple's public store over HTTPS. There is no account and no backend. It is an independent app, not part of the Apple TV brand.

## Quick start

Requirements: macOS, Xcode 15 or later, the tvOS 17 SDK, and a network connection.

```text
open Marquee.xcodeproj
```

1. Select the **Marquee** scheme.
2. Set the run destination to an **Apple TV** simulator, not **Any tvOS Device**.
3. Press Run.

The simulator target uses `CODE_SIGN_IDENTITY = -`, so no development team is required. A physical Apple TV needs your own team in Signing & Capabilities.

<details>
<summary>No supported tvOS devices are available</summary>

Xcode shows that message when the tvOS simulator platform is missing, or when no Apple TV simulator exists. Marquee does not run on Mac or iPhone.

1. **Xcode → Settings → Platforms** (older Xcode: **Components**). Download **tvOS 17** or newer.
2. **Window → Devices and Simulators → Simulators → +**.
3. Device Type: **Apple TV**. OS: the tvOS version you downloaded.
4. Choose that simulator in the toolbar and press Run.

</details>

## What you can do

| Tab | What it shows |
| --- | --- |
| Home | Top movies and top series, side by side in poster rails |
| Movies | The movie chart as a grid |
| Series | The series chart as a grid |
| Search | Movies and series together, from the system search field |

Open a poster for artwork, credit, genre, release date, and synopsis. **View in the Store** opens the title on Apple's store. Loading, empty, and failed requests each have their own state, and a failed request can be retried.

The remote moves left and right along a rail, and up and down between rails. The focused poster scales and picks up a gold edge.

## Layout

```text
Marquee.xcodeproj     target and shared scheme
Marquee/
  MarqueeApp.swift    entry
  Models/             titles and detail records
  Catalog/            store client and decoders
  Screens/            home, grids, search, detail
  Components/         posters, rails, status views
  Theme/              color and screen metrics
```

## Catalog

Charts and search use the Turkey store (`country=tr`). The interface is English.

Each chart asks two feeds at once and shows the first list that returns titles. A slow host does not block the other.

| Chart | Feeds |
| --- | --- |
| Movies | [Marketing Tools](https://rss.applemarketingtools.com/api/v2/tr/movies/top-movies/40/movies.json) and [iTunes top movies](https://itunes.apple.com/tr/rss/topmovies/limit=40/json) |
| Series | [Marketing Tools](https://rss.applemarketingtools.com/api/v2/tr/tv-shows/top-tv-seasons/40/tv-seasons.json) and [iTunes top TV seasons](https://itunes.apple.com/tr/rss/toptvseasons/limit=40/json) |

Search uses the [iTunes Search API](https://itunes.apple.com/search) after two characters. Detail uses `https://itunes.apple.com/lookup?id=ID&country=tr`. If lookup fails, the chart synopsis stays on screen.
