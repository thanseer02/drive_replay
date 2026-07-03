# Drive Replay

Drive Replay is a modern, premium smart black box application built with Flutter. It acts as your personal digital co-pilot, meticulously recording your drives, tracking vital statistics, and providing a comprehensive history of your trips—all offline-first.

## Features

- **Live Drive Tracking**: Monitors your current speed, top speed, distance, and duration in real-time.
- **Interactive Map Replays**: Uses `flutter_map` to draw your precise route path, both during a live drive and when reviewing past trips in the history.
- **Offline Storage**: All your trips are securely stored locally on your device using **Hive**, ensuring complete privacy and fast access without requiring an internet connection.
- **Premium Aesthetics**: Features a sleek, modern UI with glassmorphism effects, a dark mode aesthetic, and carefully designed typography and colors to wow users at first glance.
- **Trip History & Details**: Browse all your past recorded drives. Tapping into a trip pulls up a beautiful detail screen featuring an interactive map with the exact path you traveled and comprehensive stat breakdowns (Avg Speed, Top Speed, Duration, Distance).
- **Portrait Lock**: App is locked into portrait mode for a stable, distraction-free in-car experience.

## Technology Stack

- **Framework**: Flutter (Dart)
- **State Management**: Provider (MVVM Architecture)
- **Local Database**: Hive (for high-speed local NoSQL storage)
- **Mapping**: flutter_map (OpenStreetMap integration) & latlong2
- **Location & Sensors**: geolocator, sensors_plus

## Architecture

Drive Replay follows a clean, modular structure utilizing the MVVM (Model-View-ViewModel) pattern:

- **Models**: Defines data structures like `TripModel`, which is annotated and serialized using `hive_generator`.
- **ViewModels**: (`TripViewModel`, `HistoryViewModel`) act as the source of truth for the UI, handling business logic like GPS coordinate tracking, speed calculations, and interacting with the local Hive database.
- **Views**: Separated into distinct feature modules (`dashboard`, `trip_recording`, `history`, `auth`) containing fully reactive UI screens built with `flutter_screenutil` for perfect responsiveness.
- **Repositories**: (`TripRepository`) abstracts data persistence, ensuring ViewModels don't depend directly on Hive implementation details.

## Installation & Setup

1. **Clone the repository:**
   ```bash
   git clone <repository_url>
   cd Drive\ Replay
   ```

2. **Fetch Dependencies:**
   Since this project uses `fvm` (Flutter Version Management), ensure you have it installed.
   ```bash
   fvm flutter pub get
   ```

3. **Run Code Generation (if modifying models):**
   ```bash
   fvm dart run build_runner build --delete-conflicting-outputs
   ```

4. **Run the App:**
   ```bash
   fvm flutter run
   ```

## Privacy First

Drive Replay is designed with a privacy-first mindset. GPS coordinates and trip statistics are stored **locally** on your device using Hive. No location data is sent to external servers, making it a true offline-capable black box.

## Screenshots & Assets

- A custom, high-resolution app launcher icon has been integrated natively for both Android and iOS platforms.
- Map tiles are fetched dynamically from OpenStreetMap but no location tracking history is broadcasted.
