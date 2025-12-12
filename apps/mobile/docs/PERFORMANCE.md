# Performance Optimization Guide

This document outlines performance optimization strategies, profiling guidelines, and benchmarks for the English Learning mobile app.

---

## Performance Targets

### Frame Rate
- **Target**: Maintain 60 FPS (16.67ms per frame)
- **Critical Screens**: Game play, animations, scrolling
- **Acceptable**: Brief drops to 55 FPS during heavy operations
- **Unacceptable**: Sustained drops below 50 FPS

### Memory Usage
- **Target**: < 100MB for main app usage
- **Peak**: < 150MB during audio playback/recording
- **Critical**: No memory leaks
- **Audio Buffer**: Max 10MB for recording buffer

### App Size
- **Target**: < 20MB download size (APK/AAB)
- **Maximum**: < 30MB with all assets
- **Images**: Compressed and optimized
- **Fonts**: Only required weights included

### Network Performance
- **API Response**: < 2s for critical operations
- **Image Loading**: Progressive loading with placeholders
- **Offline First**: All core features work offline
- **Sync**: Background sync without blocking UI

### App Startup
- **Cold Start**: < 3s to interactive
- **Warm Start**: < 1s to interactive
- **Hot Reload**: < 500ms (development)

---

## Profiling Guidelines

### Using Flutter DevTools

#### 1. Launch DevTools
```bash
# Start the app in profile mode
flutter run --profile

# Open DevTools
flutter pub global activate devtools
flutter pub global run devtools
```

#### 2. Performance Profiling
- Open **Performance** tab
- Record a session during critical operations:
  - App startup
  - Game configuration screen
  - Game play with audio
  - History list scrolling
  - Screen transitions

#### 3. Frame Analysis
- Check for frames taking > 16.67ms
- Identify jank (frame drops)
- Look for:
  - Widget rebuilds
  - Layout thrashing
  - Shader compilation
  - Image decoding

#### 4. Memory Profiling
- Open **Memory** tab
- Take memory snapshots before/after operations
- Check for:
  - Memory leaks
  - Retained objects
  - Growing heap size
  - Audio buffer management

---

## Common Performance Issues & Solutions

### 1. Excessive Widget Rebuilds

**Problem**: Entire widget tree rebuilds on small state changes

**Solutions**:
```dart
// ❌ Bad: Rebuilds entire tree
BlocBuilder<AuthBloc, AuthState>(
  builder: (context, state) {
    return ComplexWidgetTree();
  },
)

// ✅ Good: Only rebuild what changes
BlocBuilder<AuthBloc, AuthState>(
  buildWhen: (previous, current) => previous.user != current.user,
  builder: (context, state) {
    return UserWidget(user: state.user);
  },
)
```

**Key Strategies**:
- Use `buildWhen` in BlocBuilder to prevent unnecessary rebuilds
- Split large widgets into smaller, focused widgets
- Use `const` constructors where possible
- Cache computed values in BLoC state

### 2. List Scrolling Performance

**Problem**: Lag when scrolling long lists

**Solutions**:
```dart
// ✅ Use ListView.builder for efficient rendering
ListView.builder(
  itemCount: sessions.length,
  itemBuilder: (context, index) {
    final session = sessions[index];
    return SessionListItem(
      key: ValueKey(session.id), // Important for item reuse
      session: session,
    );
  },
)

// ✅ Add separators efficiently
ListView.separated(
  itemCount: sessions.length,
  itemBuilder: (context, index) => SessionListItem(sessions[index]),
  separatorBuilder: (context, index) => const Divider(),
)
```

**Key Strategies**:
- Always use `.builder` constructors for lists
- Provide keys for list items
- Use `AutomaticKeepAliveClientMixin` for expensive items
- Implement pagination for very long lists

### 3. Image Loading & Caching

**Problem**: Images cause jank during loading/decoding

**Solutions**:
```dart
// ✅ Use cached network images
CachedNetworkImage(
  imageUrl: url,
  placeholder: (context, url) => const CircularProgressIndicator(),
  errorWidget: (context, url, error) => const Icon(Icons.error),
  memCacheWidth: 400, // Resize for memory efficiency
)

// ✅ Preload critical images
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  precacheImage(AssetImage('assets/images/logo.png'), context);
}
```

**Key Strategies**:
- Use `cached_network_image` package
- Specify cache dimensions to avoid full-size decoding
- Preload images before navigation
- Use appropriate image formats (WebP for web)

### 4. Audio Playback Performance

**Problem**: Audio playback causes UI stuttering

**Solutions**:
```dart
// ✅ Initialize audio player early
late AudioPlayer _audioPlayer;

@override
void initState() {
  super.initState();
  _audioPlayer = AudioPlayer();
  // Pre-warm audio system
  _audioPlayer.setVolume(0.0);
  _audioPlayer.setUrl('asset:///assets/audio/silence.mp3');
}

// ✅ Use isolates for heavy audio processing
Future<void> processAudioInBackground(Uint8List audioData) async {
  return await compute(_processAudio, audioData);
}
```

**Key Strategies**:
- Pre-initialize audio players
- Use audio focus management
- Dispose players properly
- Process audio in isolates for heavy operations

### 5. State Management Optimization

**Problem**: State updates trigger unnecessary rebuilds

**Solutions**:
```dart
// ✅ Use Equatable for efficient state comparison
class GameState extends Equatable {
  final List<Speech> speeches;
  final int currentIndex;
  final GameStatus status;

  const GameState({
    required this.speeches,
    required this.currentIndex,
    required this.status,
  });

  @override
  List<Object?> get props => [speeches, currentIndex, status];
}

// ✅ Use copyWith efficiently
GameState copyWith({
  List<Speech>? speeches,
  int? currentIndex,
  GameStatus? status,
}) {
  return GameState(
    speeches: speeches ?? this.speeches,
    currentIndex: currentIndex ?? this.currentIndex,
    status: status ?? this.status,
  );
}
```

**Key Strategies**:
- Extend `Equatable` for all states and events
- Implement efficient `copyWith` methods
- Avoid deep object comparisons in state
- Use immutable data structures

---

## Performance Testing Checklist

### Startup Performance
- [ ] Cold start < 3s on mid-range device
- [ ] Warm start < 1s
- [ ] Splash screen displays immediately
- [ ] No ANR (Application Not Responding) on startup

### UI Responsiveness
- [ ] All animations run at 60 FPS
- [ ] No jank during screen transitions
- [ ] Scrolling is smooth with 100+ items
- [ ] Button taps respond within 100ms

### Memory Management
- [ ] No memory leaks after 30 minutes of usage
- [ ] Memory usage stable during gameplay
- [ ] Audio buffer stays under 10MB
- [ ] App recovers from background properly

### Network Performance
- [ ] API calls complete within 2s on 4G
- [ ] Offline mode works seamlessly
- [ ] Background sync doesn't block UI
- [ ] Retry logic handles poor connectivity

### Audio Performance
- [ ] Audio playback starts within 500ms
- [ ] No audio stuttering during playback
- [ ] Recording works without UI lag
- [ ] Simultaneous audio operations handled

### Battery Usage
- [ ] Background sync uses minimal battery
- [ ] Audio playback doesn't drain excessively
- [ ] Location/sensors only used when needed
- [ ] Wake locks released properly

---

## Optimization Techniques

### 1. Widget Optimization

```dart
// ✅ Use const constructors
const Text('Hello World');
const Icon(Icons.home);
const SizedBox(height: 16);

// ✅ Extract expensive widgets
class ExpensiveWidget extends StatelessWidget {
  const ExpensiveWidget({super.key, required this.data});
  final Data data;

  @override
  Widget build(BuildContext context) {
    return /* complex widget tree */;
  }
}

// ✅ Use RepaintBoundary for complex widgets
RepaintBoundary(
  child: ComplexAnimatedWidget(),
)
```

### 2. Build Method Optimization

```dart
// ❌ Bad: Rebuilds list on every state change
@override
Widget build(BuildContext context) {
  return BlocBuilder<GameBloc, GameState>(
    builder: (context, state) {
      return ListView.builder(
        itemCount: state.speeches.length,
        itemBuilder: (context, index) => SpeechCard(state.speeches[index]),
      );
    },
  );
}

// ✅ Good: Only rebuild on relevant state changes
@override
Widget build(BuildContext context) {
  return BlocBuilder<GameBloc, GameState>(
    buildWhen: (previous, current) => previous.speeches != current.speeches,
    builder: (context, state) {
      return _SpeechList(speeches: state.speeches);
    },
  );
}

class _SpeechList extends StatelessWidget {
  const _SpeechList({required this.speeches});
  final List<Speech> speeches;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: speeches.length,
      itemBuilder: (context, index) => SpeechCard(speeches[index]),
    );
  }
}
```

### 3. Async Operations

```dart
// ✅ Use FutureBuilder efficiently
FutureBuilder<Data>(
  future: _dataFuture, // Store future in state, not in build
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      return DataWidget(snapshot.data!);
    }
    return const CircularProgressIndicator();
  },
)

// ✅ Use compute for heavy operations
Future<List<Result>> heavyComputation(List<Data> data) {
  return compute(_processData, data);
}

static List<Result> _processData(List<Data> data) {
  // Heavy processing here
  return results;
}
```

### 4. Lazy Loading

```dart
// ✅ Lazy load routes
final GoRouter _router = GoRouter(
  routes: [
    GoRoute(
      path: '/game',
      pageBuilder: (context, state) => MaterialPage(
        child: Builder(
          builder: (context) {
            // Lazy load BLoC
            return BlocProvider(
              create: (context) => GameBloc(
                repository: context.read<GameRepository>(),
              ),
              child: const GameScreen(),
            );
          },
        ),
      ),
    ),
  ],
);
```

---

## Build Optimization

### Release Build Configuration

**android/app/build.gradle**:
```gradle
android {
    buildTypes {
        release {
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
            
            // Enable R8 full mode
            proguardFiles 'proguard-rules.pro'
        }
    }
    
    // Enable code shrinking
    buildFeatures {
        shrinkResources true
    }
}
```

**iOS Optimizations** (ios/Runner.xcodeproj):
- Enable bitcode (if supported)
- Set optimization level to "Fastest, Smallest"
- Strip debug symbols in release

### Asset Optimization

```yaml
# pubspec.yaml
flutter:
  assets:
    # Only include necessary assets
    - assets/images/logo.png
    - assets/images/icons/
    # Exclude dev/test assets in release
```

**Image Compression**:
```bash
# Use tools to compress images
pngquant assets/images/*.png --ext .png --force
jpegoptim assets/images/*.jpg --max=85 --strip-all

# Convert to WebP for better compression
cwebp -q 80 input.png -o output.webp
```

---

## Monitoring & Benchmarks

### Key Metrics to Track

1. **Frame Rendering Time**
   - Target: < 16.67ms per frame
   - Measure: Flutter DevTools Performance tab

2. **Memory Usage**
   - Baseline: App idle
   - During game: With audio playback
   - Peak: Audio recording
   - After cleanup: Memory released

3. **App Size**
   - APK size (Android)
   - IPA size (iOS)
   - Download size vs installed size

4. **Network Requests**
   - Average response time
   - Failed requests ratio
   - Retry attempts

5. **Battery Usage**
   - Per hour of active use
   - Background sync impact
   - Audio playback drain

### Performance Tests

Create performance tests in `test/performance/`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Game screen scrolling performance', (tester) async {
    // Setup
    await tester.pumpWidget(MyApp());
    
    // Measure frame rendering
    await tester.pumpFrames(
      find.byType(ListView),
      const Duration(seconds: 5),
    );
    
    // Get frame statistics
    final binding = tester.binding;
    expect(binding.hasScheduledFrame, false);
  });
}
```

---

## Tools & Resources

### Profiling Tools
- **Flutter DevTools**: Performance, memory, network profiling
- **Android Studio Profiler**: CPU, memory, network, energy
- **Xcode Instruments**: Time profiler, allocations, leaks
- **Firebase Performance Monitoring**: Real-world performance data

### Performance Packages
- `flutter_performance_toolkit`: Performance monitoring utilities
- `flutter_cache_manager`: Advanced caching
- `flutter_native_splash`: Optimized splash screens

### Monitoring Services
- **Firebase Crashlytics**: Crash reporting
- **Firebase Performance**: Real-world metrics
- **Sentry**: Error tracking and performance
- **New Relic**: Full-stack observability

---

## Action Items

### Immediate Optimizations (M067)
1. ✅ Profile app with DevTools (all screens)
2. ✅ Identify and fix widget rebuild issues
3. ✅ Optimize list scrolling performance
4. ✅ Check for memory leaks
5. ✅ Measure and improve startup time
6. ✅ Test frame rates during gameplay
7. ✅ Optimize audio playback performance

### Ongoing Monitoring
- Monitor release build performance
- Track Firebase Performance metrics
- Review crash reports weekly
- Conduct performance regression testing
- Update benchmarks quarterly

---

## Performance Regression Prevention

### CI/CD Integration
```yaml
# .github/workflows/performance.yml
name: Performance Tests
on: [pull_request]
jobs:
  performance:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run performance tests
        run: flutter test test/performance/
      - name: Check app size
        run: |
          flutter build apk --release
          ls -lh build/app/outputs/flutter-apk/app-release.apk
```

### Code Review Checklist
- [ ] No unnecessary rebuilds added
- [ ] Lists use `.builder` constructors
- [ ] `const` constructors used where possible
- [ ] Heavy operations use isolates
- [ ] Images properly cached and sized
- [ ] State changes are granular
- [ ] No memory leaks introduced

---

**Last Updated**: December 11, 2025  
**Next Review**: After M067-M072 completion
