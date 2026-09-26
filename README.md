# Perde

Perde is a native Apple TV app for browsing movies and series. It is a catalog built for the television, written in SwiftUI for tvOS 17 and later. It is not part of the Apple TV brand.

The interface is dark and built for a 10-foot screen: a tab bar for Home, Movies, Series, and Search, poster rails and grids, and a detail screen for each title.

## Data

Perde reads Apple's public catalog over HTTPS. No API key, account, or backend is required.

Charts use the Turkey store (`country` code `tr`):

- Top movies: `https://rss.applemarketingtools.com/api/v2/tr/movies/top-movies/40/movies.json`
- Top series: `https://rss.applemarketingtools.com/api/v2/tr/tv-shows/top-tv-seasons/40/tv-seasons.json`

Those marketing-tools routes currently fail or time out for movies and TV. Perde still requests them, and at the same time requests the live iTunes RSS charts for the same store:

- `https://itunes.apple.com/tr/rss/topmovies/limit=40/json`
- `https://itunes.apple.com/tr/rss/toptvseasons/limit=40/json`

The first feed that returns titles is shown. An empty chart stays empty.

Search calls the iTunes Search API as you type (`https://itunes.apple.com/search`, `country=tr`), once for movies (`media=movie`, `entity=movie`) and once for series (`media=tvShow`, `entity=tvSeason`). The movie filter currently returns an empty set, so Perde also queries the same endpoint without a media filter and keeps feature films and TV seasons whose titles match the query.

The detail screen calls `https://itunes.apple.com/lookup?id=ID&country=tr` for the synopsis, genre, release date, artwork, credit, and store link. **View in the Store** opens that link (`trackViewUrl` for a movie, `collectionViewUrl` for a season).

Every screen that fetches has a loading state, an empty state, and an error state with **Try Again**.

## Requirements

- A Mac with Xcode 15 or later
- The tvOS 17 SDK
- An Apple TV simulator running tvOS 17 or later
- A network connection so the simulator can reach Apple's catalog

Signing is set up for the simulator (`CODE_SIGN_IDENTITY = -`). A development team is not required to run Perde there. Installing on a physical Apple TV needs your own team in Signing & Capabilities.

## Run

1. Open `Perde.xcodeproj` in Xcode.
2. Select the **Perde** scheme.
3. Select an Apple TV simulator as the run destination.
4. Press Run.

Home shows the top movies and top series. Movies and Series show those charts as grids. Search updates as you type. Open a poster for the detail screen.
