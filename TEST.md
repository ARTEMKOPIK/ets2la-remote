# Test Documentation

This document describes the testing strategy, current test coverage, gaps, and patterns for the ETS2LA Remote Flutter application.

## Table of Contents

1. [Test Strategy and Philosophy](#test-strategy-and-philosophy)
2. [Current Test Coverage](#current-test-coverage)
3. [What's Missing](#whats-missing)
4. [Testing Patterns](#testing-patterns)
5. [How to Run Tests](#how-to-run-tests)
6. [CI Testing](#ci-testing)
7. [Coverage Targets](#coverage-targets)

---

## Test Strategy and Philosophy

### Guiding Principles

1. **Test behavior, not implementation** — Tests verify the public contract of classes and functions. Internal refactoring shouldn't require test changes unless the API changes.

2. **Defense against regression** — The primary goal is catching unintentional behavior changes, especially in:
   - Data serialization/deserialization (JSON encoding, QR codec)
   - Network protocols (WebSocket message formats)
   - State machines (connection stages, reconnect logic)
   - User-facing calculations (speed conversion, trip statistics)

3. **Fast, isolated unit tests** — Tests run without network calls, file system access, or Flutter widget rendering. Mock external dependencies.

4. **Coverage of edge cases** — Bug reports often stem from malformed input (garbage JSON, invalid QR codes, corrupted telemetry). Tests verify graceful handling.

### What's in Scope

| Category | Examples |
|----------|----------|
| **Models** | `TripEntry`, `ConnectionProfile`, `NavPosition`, `NavRoute`, telemetry event classes |
| **Services** | `ProfileQrCodec`, `ReconnectBackoff`, `TripLogService`, `ApiService` (unit portions) |
| **Utilities** | Speed conversion, duration calculations, JSON encoding |
| **Edge case handling** | Null values, type coercion, malformed input |

### What's NOT in Scope (Currently)

- **Widget tests** — Full Flutter widget rendering requires device/emulator
- **Integration tests** — Network communication with live ETS2LA backend
- **Provider integration** — `ChangeNotifier` subclasses need full Flutter context

---

## Current Test Coverage

### Summary

| Metric | Value |
|--------|-------|
| Test files | 3 |
| Test lines | 235 |
| Source files | 60 |
| Source lines | ~15,592 |
| Coverage ratio | ~1.5% by lines |

### Tested Files

#### 1. `test/profile_qr_codec_test.dart` (89 lines)

**Source:** `lib/services/profile_qr_codec.dart`

**What's tested:**
- Encoding produces valid `ets2la://profile` URLs
- Required fields (name, host) are included
- Optional MAC address handling
- Round-trip encode/decode preserves data
- ID regeneration on decode (local DB gets fresh row)
- Invalid input rejection (wrong scheme, missing fields, malformed MAC)

**Test count:** 7 tests

```dart
test('produces a valid ets2la://profile URL with required fields', () { ... });
test('includes mac when present', () { ... });
test('roundtrips a profile through encode/decode preserving host/mac/name', () { ... });
test('regenerates the id on import so the local DB gets a fresh row', () { ... });
test('rejects unknown schemes and hosts', () { ... });
test('requires both name and host to be present', () { ... });
test('drops malformed MAC but keeps the rest of the profile', () { ... });
```

#### 2. `test/trip_entry_test.dart` (90 lines)

**Source:** `lib/models/trip_entry.dart`

**What's tested:**
- Duration calculation (`endedAt - startedAt`)
- Autopilot fraction clamping (0.0 to 1.0)
- JSON serialization/deserialization round-trip
- Invalid input handling (null, empty, garbage JSON)
- Partial list parsing (skips malformed entries)

**Test count:** 5 tests

```dart
test('duration equals end - start', () { ... });
test('autopilotFraction clamps to [0, 1]', () { ... });
test('encode/decode roundtrip preserves every field', () { ... });
test('decodeAll returns empty list on null / garbage / wrong shape', () { ... });
test('decodeAll skips individual malformed entries', () { ... });
```

#### 3. `test/reconnect_backoff_test.dart` (56 lines)

**Source:** `lib/services/reconnect_backoff.dart`

**What's tested:**
- Initial delay matches constructor value
- Exponential doubling until cap
- Cap is never exceeded
- Reset returns to initial delay
- Jitter stays within specified fraction

**Test count:** 4 tests

```dart
test('first delay is approximately the initial duration', () { ... });
test('doubles on each attempt until capped', () { ... });
test('reset starts over from initial', () { ... });
test('jitter keeps result within ±jitter fraction of base', () { ... });
```

---

## What's Missing

### High Priority Gaps

#### Models (Data + Logic)

| File | Coverage Status |
|------|-----------------|
| `lib/models/telemetry.dart` | **Not tested** — `NavPosition.fromJson`, `NavRoute.fromJson`, `_num()` coercion |
| `lib/models/connection_profile.dart` | **Partially tested** — JSON serialization indirectly tested via QR codec; `copyWith`, `encodeAll`, `decodeAll` not tested |
| `lib/models/plugin_state.dart` | **Unknown** — file may not exist or needs checking |
| `lib/models/telemetry_event.dart` | **Not tested** — event parsing, null handling |

#### Services (Pure Logic)

| File | Coverage Status |
|------|-----------------|
| `lib/services/api_service.dart` | **Not tested** — URL building, status code handling, JSON parsing |
| `lib/services/trip_log_service.dart` | **Not tested** — `loadTrips()`, `clear()`, aggregation logic |
| `lib/services/port_probe_service.dart` | **Not tested** — port discovery |
| `lib/services/lan_discovery_service.dart` | **Not tested** — mDNS discovery |
| `lib/services/wake_on_lan_service.dart` | **Not tested** — WoL packet construction |

#### Providers (State Machines)

| File | Coverage Status |
|------|-----------------|
| `lib/providers/connection_provider.dart` | **Not tested** — connection stages, port clamping, host stripping, firewall streak |
| `lib/providers/telemetry_provider.dart` | **Not tested** — telemetry updates, null handling |
| `lib/providers/settings_provider.dart` | **Partially tested** — enum clamping via constructor only |
| `lib/providers/update_provider.dart` | **Not tested** |

#### WebSocket Services

| File | Coverage Status |
|------|-----------------|
| `lib/services/websocket_service.dart` | **Not tested** — JSON decoding, state machine, subscriptions |
| `lib/services/navigation_ws_service.dart` | **Not tested** |
| `lib/services/pages_ws_service.dart` | **Not tested** |

#### Utilities

| File | Coverage Status |
|------|-----------------|
| `lib/utils/speed_conversion.dart` | **Does not exist** — but speed conversion lives in `AppSettings` |
| `lib/utils/toast.dart` | **Not testable** — Flutter widget |
| `lib/utils/haptics.dart` | **Not testable** — platform channel |

### Testing Priorities

1. **First:** Model serialization (`telemetry.dart`, `ConnectionProfile`)
2. **Second:** Service logic with pure functions (`ApiService`, `TripLogService.loadTrips`)
3. **Third:** Utility calculations (speed conversion, port clamping)

---

## Testing Patterns

### How Existing Tests Are Structured

#### Test Grouping

Tests are grouped by the method or feature being tested:

```dart
group('ProfileQrCodec.encode', () {
  test('produces a valid ets2la://profile URL with required fields', () { ... });
  // ...
});
```

#### Assertions

- **Exact equality:** `expect(value, expectedValue)`
- **Relational:** `expect(value, greaterThan(0))`
- **Numeric floating-point:** `expect(value, closeTo(expected, 1e-6))`
- **Nullability:** `expect(value, isNull)` / `expect(value, isNotNull)`
- **Collection length:** `expect(list.length, 1)`
- **String containment:** `expect(text, contains('pattern'))`
- **Type checking:** `expect(value, isA<Type>())`

#### Test Data Construction

- Inline literals for simple cases
- Helper functions for complex encoding:

```dart
String _encodedSingle(TripEntry e) {
  // Manual JSON construction to test partial parsing
  final m = e.toJson();
  // ... build string manually
  return buf.toString();
}
```

#### Edge Case Patterns

- **Invalid JSON:** Null, empty string, random text, partial objects
- **Type coercion:** `num` → `double`, string numbers
- **Boundary values:** Min/max, zero, negative, huge values

---

## How to Run Tests

### Prerequisites

```bash
# Flutter SDK must be installed and in PATH
flutter --version  # Should output Flutter 3.x.x
```

### Running Tests

```bash
# Run all tests
flutter test

# Run a specific test file
flutter test test/profile_qr_codec_test.dart

# Run tests matching a description
flutter test --name "ProfileQrCodec"

# Run with coverage (requires coverage package)
flutter test --coverage
```

### Interpreting Results

- **Pass:** All assertions succeeded
- **Fail:** Stack trace points to failed assertion
- **Skip:** `skip: 'reason'` annotation (not currently used)

### Debugging Failed Tests

```bash
# Run in verbose mode to see print statements
flutter test -v

# Run a single test
flutter test test/profile_qr_codec_test.dart --name "roundtrips"
```

---

## CI Testing

### Current State

The project has GitHub Actions workflows in `.github/workflows/`:

1. **Android CI** — Builds debug APK (`flutter build apk --debug`)
2. **Code quality** — Runs `flutter analyze` and `flutter format --check`

Tests are NOT currently run in CI.

### Recommended CI additions

```yaml
# Add to android.yml or create separate test.yml
- name: Run tests
  run: flutter test

- name: Upload test results
  uses: actions/upload-artifact@v4
  with:
    name: test-results
    path: test_results/
```

### Recommended: Code Coverage

1. Add `coverage` to `pubspec.yaml` dev_dependencies:
   ```yaml
   dev_dependencies:
     flutter_test:
       sdk: flutter
     coverage: ^1.6.0
   ```

2. Generate reports in CI:
   ```bash
   flutter test --coverage
   gen_coverage_html coverage/lcov.info --out=coverage/html
   ```

3. Upload to a coverage service (Codecov, Coveralls, etc.)

---

## Coverage Targets

### Current Coverage

| Category | Approximate Coverage |
|----------|-------------------|
| Source lines | ~15,592 |
| Test lines | 235 |
| **Overall line coverage** | **~1.5%** |
| Files with tests | 3 of 60 |

### Recommendations

#### Minimum Viable Coverage by Release

| Milestone | Target Coverage | Focus Areas |
|----------|---------------|-------------|
| v1.1.0 | 10% | Model serialization, critical services |
| v1.2.0 | 20% | All models, service logic |
| v1.3.0 | 30% | Providers, utilities |

#### Priority Files for Coverage

1. **`lib/models/telemetry.dart`** — Defensive input coercion is the core reliability layer
2. **`lib/models/trip_entry.dart`** — Already partially tested, expand to full coverage
3. **`lib/models/connection_profile.dart`** — JSON and list handling
4. **`lib/services/api_service.dart`** — URL building, error handling
5. **`lib/providers/settings_provider.dart`** — Port clamping, enum safety

### Coverage Exclusions

These files don't need unit tests:
- **`lib/main.dart`** — App entry point, requires full Flutter context
- **`lib/screens/*.dart`** — Widget tests instead
- **`lib/widgets/*.dart`** — Widget tests instead
- **`lib/theme/app_theme.dart`** — Styling, visual verification
- **Any file relying on platform channels** (`MethodChannel`) — Integration tests only

---

## Appendix: Files Reference

### Source File Structure

```
lib/
├── main.dart                    # App entry point (NOT tested)
├── models/                     # Data models
│   ├── connection_profile.dart # PARTIALLY tested (via QR codec)
│   ├── telemetry.dart         # NOT tested
│   ├── telemetry_event.dart   # NOT tested
│   ├── trip_entry.dart       # Tested ✓
│   └── plugin_state.dart    # CHECK FILE EXISTS
├── providers/                  # State management
│   ├── connection_provider.dart    # NOT tested
│   ├── settings_provider.dart       # PARTIALLY tested
│   ├── telemetry_provider.dart     # NOT tested
│   └── update_provider.dart       # NOT tested
├── services/                   # Business logic
│   ├── api_service.dart                # NOT tested
│   ├── connectivity_service.dart      # (may not exist)
│   ├── keep_alive_service.dart        # NOT testable (platform)
│   ├── lan_discovery_service.dart      # NOT tested
│   ├── local_server.dart              # NOT testable (network)
│   ├── navigation_ws_service.dart    # NOT tested
│   ├── notification_update_service.dart # NOT testable (platform)
│   ├── pages_ws_service.dart         # NOT tested
│   ├── port_probe_service.dart       # NOT tested
│   ├── profile_qr_codec.dart       # Tested ✓
│   ├── reconnect_backoff.dart       # Tested ✓
│   ├── shortcut_service.dart        # (may not exist)
│   ├── telemetry_feedback_service.dart # NOT testable (platform)
│   ├── trip_log_service.dart        # NOT tested
│   ├── update_service.dart          # NOT testable (platform)
│   ├── wake_on_lan_service.dart   # NOT tested
│   └── websocket_service.dart    # NOT tested
├── screens/                     # UI screens (widget tests)
├── widgets/                    # UI widgets (widget tests)
├── theme/                      # Styling
│   └── app_theme.dart           # NOT tested
└── utils/                       # Utilities
    ├── haptics.dart              # NOT testable (platform)
    ├── text_scale.dart          # NOT testable (platform)
    └── toast.dart               # NOT testable (Flutter)
```

### Test File Structure

```
test/
├── reconnect_backoff_test.dart  # ✓ Tested
├── trip_entry_test.dart          # ✓ Tested
└── profile_qr_codec_test.dart    # ✓ Tested
```

---

## Changelog

- **2024-04-24** — Initial TEST.md created
  - Analyzed 3 existing test files (235 lines)
  - Mapped 60 source files (~15,592 LOC)
  - Identified major coverage gaps
  - Documented testing patterns and CI recommendations