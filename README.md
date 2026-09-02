# Flutter BLoC & GoRouter

A production-grade Flutter reference project demonstrating scalable architecture patterns using **GoRouter** (declarative routing with stateful shell navigation), **flutter_bloc** (BLoC & Cubit state management), **Repository Pattern**, **Dio** (resilient HTTP client with typed error handling), and **SharedPreferences** (local persistence).

Powered by the public [JSONPlaceholder](https://jsonplaceholder.typicode.com/) REST API.

---

## Architecture Overview

This project is built following Clean Architecture and separation-of-concerns principles, structured across five core layers:

```
┌────────────────────────────────────────────────────────┐
│                      UI (Views)                        │
│   Declarative widgets, debounced search, animations    │
└───────────────────────────┬────────────────────────────┘
                            │ Dispatches Events / Calls Methods
                            ▼
┌────────────────────────────────────────────────────────┐
│               State Management (BLoC / Cubit)          │
│   Event-driven pagination, form validation, theming    │
└───────────────────────────┬────────────────────────────┘
                            │ Requests Data
                            ▼
┌────────────────────────────────────────────────────────┐
│                     Repositories                       │
│    Data coordination, in-memory caching, sanitization  │
└───────────────────────────┬────────────────────────────┘
                            │
              ┌─────────────┴─────────────┐
              ▼                           ▼
┌───────────────────────────┐ ┌───────────────────────────┐
│     ApiClient (Dio)       │ │   LocalStorageService     │
│ Timeouts, Error Mapping,  │ │ SharedPreferences caching │
│ Interceptors, Logging     │ │ (Theme, Bookmarks, Auth)  │
└───────────────────────────┘ └───────────────────────────┘
```

---

## Key Technical Highlights

### 1. Advanced Declarative Routing with GoRouter
- **Stateful Nested Navigation**: Utilizes `StatefulShellRoute.indexedStack` to preserve bottom navigation tab state and scroll position across tab switches.
- **Route Guards & Dynamic Redirects**: Protected routes (such as `/create-post`) redirect unauthenticated visitors to `/login?from=<location>`, returning them automatically upon successful authentication.
- **Type-Safe Path & Query Parameters**: Clean parameter parsing for detail views (`/users/:id`, `/posts/:id`) and filter queries (`/posts?userId=1`).
- **Reactive Navigation**: Leverages `refreshListenable` bound to `AuthCubit.stream` to react instantly to session changes.

### 2. State Management (BLoC & Cubit)
- **Event-Driven BLoC (`PostsBloc`)**: Manages the post feed with infinite scroll pagination, query filtering, pull-to-refresh, optimistic post insertion, and pagination error recovery.
- **Lightweight Cubits**:
  - `UsersCubit` & `UserDetailsCubit`: Fast async data fetching and debounced search.
  - `CreatePostCubit`: Pure form validation with instant character constraint feedback.
  - `FavoritesCubit`: Synchronous local cache updates backed by persistent storage.
  - `AuthCubit`: Authentication lifecycle and mock session management.
  - `SettingsCubit`: System, Light, and Dark theme mode persistence.
- **Scoped vs. Global Providers**: Global dependencies provided at app root; detail screen cubits strictly scoped to route lifecycles to prevent memory leaks.

### 3. Networking & Error Resilience
- **Configured Dio Client**: Request/response timeouts, custom interceptors for Bearer token injection, and safe logging.
- **Typed `ApiException` Handling**: Maps HTTP status codes (400, 404, 500), connection timeouts, and offline states into user-friendly error models.
- **Offline / In-Memory Mock Cache**: Created posts (IDs ≥ 101) are stored in a local repository cache so they seamlessly appear in feeds, detail views, and bookmark lists without API 404s.

### 4. Design System & UI/UX
- **Material 3 Theming**: Tailored light and dark themes with curated HSL-derived color tokens.
- **Micro-Animations & Feedback**: Shimmer skeleton loaders for async states, custom floating snackbars, and interactive badge counters.
- **Safe State Handling**: Comprehensive empty states and retry-enabled error banners across all screens.

---

## Directory Structure

```
lib/
├── core/
│   ├── api/
│   │   ├── api_client.dart            # Dio HTTP wrapper with interceptors & error mapping
│   │   ├── api_endpoints.dart         # REST API endpoint constants
│   │   ├── api_exception.dart         # Custom typed exception model
│   │   └── api_interceptors.dart      # Auth header injector & sanitized logger
│   ├── config/
│   │   └── app_config.dart            # Environment settings & timeouts
│   ├── storage/
│   │   └── local_storage_service.dart # SharedPreferences persistence service
│   ├── theme/
│   │   ├── app_colors.dart            # Brand palette, gradients, and avatar token pools
│   │   └── app_theme.dart             # Material 3 light & dark theme specifications
│   ├── utils/
│   │   ├── app_bloc_observer.dart     # Global BLoC event & transition logger
│   │   ├── app_feedback.dart          # Reusable snackbars and user alerts
│   │   └── debouncer.dart             # Input debounce utility
│   └── widgets/
│       ├── app_dialogs.dart           # Confirmation dialogs
│       ├── app_empty_state.dart       # Reusable empty view
│       ├── app_error_state.dart       # Reusable error view with retry
│       ├── app_loading_indicator.dart # Centralized loading indicator
│       └── app_shimmer_skeleton.dart  # Custom pulse shimmer skeleton loader
├── data/
│   ├── models/
│   │   ├── comment.dart               # Typed Comment model
│   │   ├── post.dart                  # Typed Post model
│   │   └── user.dart                  # User, Address, Geo, and Company models
│   └── repositories/
│       ├── favorites_repository.dart  # Bookmark ID persistence
│       ├── history_repository.dart    # Recently viewed post history
│       ├── post_repository.dart       # Posts, pagination, comments & local cache
│       └── user_repository.dart       # User profiles and authored posts
├── features/
│   ├── app/
│   │   └── app.dart                   # Root MultiRepositoryProvider & MultiBlocProvider
│   ├── auth/
│   │   └── cubit/auth_cubit.dart      # Session state & auth status
│   ├── favorites/
│   │   ├── cubit/favorites_cubit.dart # Bookmarks state management
│   │   └── views/favorites_screen.dart # Saved bookmarks view
│   ├── history/
│   │   └── cubit/history_cubit.dart   # Recently viewed posts state
│   ├── home/
│   │   └── views/home_screen.dart     # Dashboard, live stats, search, & feature navigation
│   ├── posts/
│   │   ├── bloc/                      # Paginated posts feed BLoC
│   │   ├── cubit/                     # Form & detail cubits
│   │   └── views/                     # Feed, detail, and creation screens
│   ├── settings/
│   │   ├── cubit/settings_cubit.dart  # Theme and preference state
│   │   └── views/                     # Settings screen and login screen
│   └── users/
│       ├── cubit/                     # Directory and profile cubits
│       └── views/                     # Searchable directory & author profile screens
├── router/
│   ├── app_router.dart                # Central GoRouter configuration & guards
│   └── route_names.dart               # Type-safe route constants
└── main.dart                          # App entry point
```

---

## Getting Started

### Prerequisites
- Flutter SDK `^3.12.0` or higher
- Dart SDK `^3.12.0` or higher

### Installation & Run

1. **Clone and enter repository**:
   ```bash
   git clone <repository-url>
   cd flutter_bloc_go_router
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the test suite**:
   ```bash
   flutter test
   ```

4. **Run static analysis**:
   ```bash
   flutter analyze
   ```

5. **Launch the application**:
   ```bash
   flutter run
   ```

---

## Test Coverage

The project includes a full unit and widget test suite covering:
- **Models**: JSON deserialization and serialization integrity.
- **Network & Storage**: Interceptor token injection, error status mapping, and SharedPreferences storage persistence.
- **BLoCs & Cubits**: State emissions, search filtering, optimistic updates, and form validation using `bloc_test`.
- **Navigation & Routing**: Route guards, parameter passing, and stateful shell tab preservation.
- **Widget Tests**: Screen rendering, form validation errors, confirmation dialogs, and reusable core widgets.

To run all tests:
```bash
flutter test
```
