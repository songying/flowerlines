# Flower Lines — Native iOS & Android Port: Implementation Plan

## Context

The web game at `index.html` is a single-file HTML5 Canvas puzzle (Lines98-style, 9×9 grid, 7 flower types). This plan describes creating two native subprojects — `ios/` and `android/` — that faithfully port the game as standalone native apps, with monetization (interstitial ads), bubble sound effects, and a volume/mute control UI. No WebView is used.

---

## Requirements

### Base Port
- Pixel-faithful recreation of all 7 flower types using native vector drawing APIs
- Same game logic: BFS pathfinding, 4-direction line detection, spawn/eliminate turn flow
- Adaptive layout for all screen sizes (iPhone SE → iPad Pro 12.9", small Android → 12" tablet)
- Portrait and landscape support

### Additional Features
1. **Ads**: Interstitial ad on the Game Over screen. "▶ Watch Ad & Play Again" button launches a fullscreen ad with a 3-second countdown overlay; "✕ Skip" appears after 3s. "Play Again" (no ad) also available.
2. **Sound effects**: Bubble-style SFX for select, move, eliminate, and game over.
3. **Volume control**: Slider UI to independently adjust BGM/SFX volumes, with mute toggles. Persisted across sessions.
4. **Default volume**: BGM and SFX default to **45%** on first launch.

---

## Directory Structure

### iOS (`ios/`)

```
ios/
├── FlowerLines.xcodeproj/
├── Podfile                         (CocoaPods: Google-Mobile-Ads-SDK)
└── FlowerLines/
    ├── AppDelegate.swift
    ├── SceneDelegate.swift
    ├── ViewController.swift
    ├── Game/
    │   ├── GameState.swift          (board, score, phase, animQueue)
    │   ├── GameLogic.swift          (BFS, line detection, scoring, turn flow)
    │   └── AnimationQueue.swift     (AnimKind enum + AnimItem struct)
    ├── Rendering/
    │   ├── GameView.swift           (CADisplayLink render loop + tap input)
    │   ├── FlowerRenderer.swift     (CGContext petal drawing — 7 types)
    │   ├── GridRenderer.swift       (grid, highlights, score bar, game over)
    │   └── SidebarRenderer.swift    (next-flower preview panel)
    ├── Layout/
    │   └── LayoutCalculator.swift   (uniform scale formula for all devices)
    ├── Audio/
    │   ├── AudioManager.swift       (BGM + SFX routing, volume, 45% default)
    │   └── SoundEffect.swift        (AVAudioPlayer preload/play helpers)
    ├── Ads/
    │   └── AdManager.swift          (GADInterstitialAd + 3s countdown overlay)
    ├── UI/
    │   └── VolumeControlView.swift  (UISlider overlay, mute toggles)
    ├── Persistence/
    │   └── ScoreStore.swift         (UserDefaults: high score + volumes)
    └── Resources/
        ├── bgm.mp3
        ├── sfx_select.wav
        ├── sfx_move.wav
        ├── sfx_eliminate.wav
        ├── sfx_gameover.wav
        └── Assets.xcassets/
```

### Android (`android/`)

```
android/
├── build.gradle
├── settings.gradle
├── google-services.json             (fill in after AdMob setup)
└── app/
    ├── build.gradle                 (minSdk 24, compileSdk 35)
    └── src/main/
        ├── AndroidManifest.xml
        ├── res/
        │   ├── layout/activity_main.xml
        │   ├── raw/
        │   │   ├── bgm.mp3
        │   │   ├── sfx_select.wav
        │   │   ├── sfx_move.wav
        │   │   ├── sfx_eliminate.wav
        │   │   └── sfx_gameover.wav
        │   └── values/{strings,colors}.xml
        └── java/com/flowerlines/
            ├── MainActivity.kt
            ├── game/{GameState,GameLogic,AnimationQueue}.kt
            ├── rendering/{GameView,FlowerRenderer,GridRenderer,SidebarRenderer}.kt
            ├── layout/LayoutCalculator.kt
            ├── audio/{AudioManager,SoundEffectPool}.kt
            ├── ads/AdManager.kt
            ├── ui/VolumeControlView.kt
            └── persistence/ScoreStore.kt
```

---

## Step 1: Core Game Logic

Port from JS identically. No platform differences.

**GameState fields:** `board[9][9]` (null/−1=empty, 0–6=type), `score`, `highScore`, `phase` (IDLE/SELECTED/ANIMATING/GAMEOVER), `selected`, `validMoves`, `nextFlowers[3]`, `animQueue`, `eliminatingCells`, `spawningCells`, `animStart`

**GameLogic functions:**

| Function | Description |
|----------|-------------|
| `bfsReachable(board, start)` | Returns Set of all empty cells reachable from start |
| `findPath(board, from, to)` | BFS with parent map, returns ordered cell array |
| `findLines(board)` | Scans 4 directions (→ ↓ ↘ ↙), returns matched cells |
| `calcScore(n)` | `10 + (n − 5) × 5` for n ≥ 5, else 0 |
| `genNextFlowers()` | Returns 3 random ints 0–6 |
| `emptyCells(board)` | Returns all cells where value is null/−1 |

**Easing functions (exact JS ports):**
```
easeInOut(t) = t<0.5 ? 2t² : −1+(4−2t)t
easeOut(t)   = 1−(1−t)²
elasticOut(t) = 2^(−10t) × sin((t−0.075)×2π/0.3) + 1
```

**AnimationQueue — 3 types:**

| Kind | Duration | Easing | Effect |
|------|----------|--------|--------|
| MOVE | max(300, pathLen×55) ms | easeInOut | Lerp flower along BFS path |
| ELIMINATE | 450 ms | easeOut | Shrink radius + fade alpha: both = 1−t |
| SPAWN | 400 ms | elasticOut | Scale radius by t; alpha = min(1, rawT×4) |

---

## Step 2: Layout Calculator

Single formula handles every device — no conditional branches:

```
cellFromWidth  = usableW / (9 + 130/56)   // fit grid+sidebar in width
cellFromHeight = usableH / (9 + 60/56)    // fit grid+header in height
cellSize = min(cellFromWidth, cellFromHeight)
scale    = cellSize / 56
```

Derived values (all × scale relative to source px):
- `flowerRadius` = 20 × scale
- `sidebarFlowerRadius` = 22 × scale
- `headerHeight` = 60 × scale
- `sidebarWidth` = 130 × scale
- All text sizes = source_pt × scale

iOS: subtract `safeAreaInsets` before computing. Android: apply `WindowInsets`.
Content is centered (letterboxed on the long axis).

---

## Step 3: Flower Renderer

All 7 types use **translate to center + rotate by (360°/n × i)** per petal.

### Petal geometry (in units of radius `r`)

| Type | Petals | Method | Key values |
|------|--------|--------|------------|
| Red | 5 | quadTo | CP: (±0.55r, −0.45r) → end: (0, −r) |
| Orange | 6 | circle | center (0, −0.52r), r=0.38r |
| Yellow | 8 | quadTo | CP: (±0.22r, −0.5r) → end: (0, −r) |
| Green | 4 | cubicTo | CP1: (±0.75r, −0.1r), CP2: (±0.75r, −0.9r) → end: (0, −r) |
| Teal | 6 | lines | (0,0)→(±0.22r,−0.48r)→(0,−r), close |
| Blue | 5 | quadTo | CP: (±0.72r, −0.38r) → end: (0, −r) |
| Purple | 7 | quadTo | CP: (±0.28r, −0.52r) → end: (0, −r) |

Center decoration (all types): white ring radius=0.28r + colored dot radius=0.12r.

Shadow: offset (0, +2px), blur 5px, `rgba(0,0,0,0.28)`.

### API translation

| JS Canvas | Swift (UIBezierPath) | Kotlin (Path) |
|-----------|---------------------|---------------|
| `quadraticCurveTo(cx,cy, x,y)` | `addQuadCurve(to:(x,y), controlPoint:(cx,cy))` | `quadTo(cx,cy, x,y)` |
| `bezierCurveTo(c1,c2,x,y)` | `addCurve(to:, cp1:, cp2:)` | `cubicTo(c1x,c1y,c2x,c2y,x,y)` |
| `arc(cx,cy,r,0,2π)` | `addArc(withCenter:radius:startAngle:endAngle:)` | `addCircle(cx,cy,r,CW)` |
| `ctx.rotate(radians)` | `ctx.rotate(by: radians)` | `canvas.rotate(Math.toDegrees(rad).toFloat())` ⚠️ degrees! |
| `shadowBlur=5, offsetY=2` | `ctx.setShadow(offset:CGSize(0,2), blur:5)` | Separate pass: translate(0,2) + BlurMaskFilter(5) |
| `globalAlpha=a` | `ctx.setAlpha(a)` | `paint.alpha = (a×255).toInt()` |

---

## Step 4: Rendering Pipeline

Draw order (same as JS source):
1. Sidebar background + 3 next-flower cards (float: `sin(ts/900 + i×2.1) × 4` px)
2. Grid gradient background + checkerboard + grid lines
3. Valid-move highlights (yellow 40% overlay + center dot)
4. Static flowers (skip selected cell + animating cells)
5. Animating flowers (MOVE lerp / ELIMINATE shrink-fade / SPAWN elastic-scale)
6. Selected-flower yellow glow ring (`sin(ts/180)` pulse ±3px radius, ±7% scale)
7. Score bar (score, high score, New Game button)
8. Game Over overlay (when phase=GAMEOVER): dim + panel + two buttons

**Timestamps:**
- iOS: `ts = CADisplayLink.timestamp × 1000` (ms)
- Android: `ts = Choreographer frameTimeNanos / 1_000_000` (ms)

---

## Step 5: Audio System

### BGM
- iOS: `AVAudioPlayer`, session category `.ambient`, `numberOfLoops = -1`
- Android: `MediaPlayer`, `isLooping = true`
- Default volume: **0.45** (45%)
- Persisted: key `"bgm_volume"` (Float 0–1)

### SFX Files

| File | Duration | Trigger |
|------|----------|---------|
| `sfx_select.wav` | ~150ms | Flower tapped (SELECTED phase) |
| `sfx_move.wav` | ~200ms | MOVE animation starts |
| `sfx_eliminate.wav` | ~400ms | ELIMINATE animation starts |
| `sfx_gameover.wav` | ~600ms | Phase → GAMEOVER |

Source: [freesound.org](https://freesound.org) (search "bubble pop", CC0 license) or synthesize at runtime.

iOS playback: `AVAudioPlayer` preloaded instances
Android playback: `SoundPool` (low-latency, for short clips)

### Volume Control UI

Overlay panel toggled by a 🔊 icon button in the score bar:
- BGM: slider (0–1) + mute toggle
- SFX: slider (0–1) + mute toggle
- Close button

iOS: `UISlider` in a semi-transparent `UIView` over `GameView`
Android: `SeekBar` in a `FrameLayout` overlay

Changes apply immediately and persist. Mute: save volume → set 0. Unmute: restore saved volume.

---

## Step 6: Ads (AdMob Interstitial)

### UX Flow

```
Board fills up → phase=GAMEOVER → sfx_gameover plays
↓
Game Over panel rendered on canvas with TWO buttons:
  [▶ Watch Ad & Play Again]  ← primary green button
  [Play Again]               ← secondary muted button

Tap [▶ Watch Ad & Play Again]:
  → AdManager.showAd()
  → Interstitial launches fullscreen
  → Countdown overlay appears: 3 → 2 → 1
  → [✕ Skip] button appears
  → User taps Skip → initGame()

Tap [Play Again]:
  → initGame() immediately (no ad)
```

### Canvas Layout Changes

Two button rects drawn in `drawGameOver()`:
```
GOB_AD = { x: 142, y: 340, w: 220, h: 44 }  // "Watch Ad & Play Again"
GOB    = { x: 142, y: 394, w: 220, h: 38 }  // "Play Again" (smaller)
```

Click handling: check `GOB_AD` first, then `GOB`, both only in GAMEOVER phase.

### iOS Implementation

```ruby
# Podfile
pod 'Google-Mobile-Ads-SDK'
```

```swift
// Info.plist
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-XXXXXXXX~XXXXXXXXXX</string>  // your App ID

// AdManager.swift
func loadAd() {
    GADInterstitialAd.load(withAdUnitID: adUnitID, request: GADRequest()) { ad, _ in
        self.interstitial = ad
        self.interstitial?.fullScreenContentDelegate = self
    }
}

func showAd(from vc: UIViewController, onFinished: @escaping () -> Void) {
    guard let ad = interstitial else { onFinished(); loadAd(); return }
    self.onFinished = onFinished
    ad.present(fromRootViewController: vc)
    showCountdownOverlay(in: vc.view.window!, onSkip: onFinished)
}

// Countdown overlay: UIView pinned to window, Timer ×3 (1s each)
// After 3 ticks: hide label, show "✕ Skip" UIButton
```

### Android Implementation

```groovy
// app/build.gradle
implementation 'com.google.android.gms:play-services-ads:23.0.0'
```

```xml
<!-- AndroidManifest.xml -->
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-XXXXXXXX~XXXXXXXXXX"/>
```

```kotlin
// AdManager.kt
fun showAd(onFinished: () -> Unit) {
    val ad = interstitialAd ?: run { onFinished(); loadAd(); return }
    ad.fullScreenContentCallback = object : FullScreenContentCallback() {
        override fun onAdDismissedFullScreenContent() { onFinished(); loadAd() }
    }
    ad.show(activity)
    showCountdownOverlay(onFinished)
}

// Countdown: WindowManager.addView(FrameLayout)
// CountDownTimer(3000, 1000): tick → update "3"/"2"/"1" TextView
// onFinish: replace with "✕ Skip" Button
// Button.onClick → WindowManager.removeView() + onFinished()
```

### Test Ad Unit IDs (use during development)

| Platform | Test ID |
|----------|---------|
| iOS | `ca-app-pub-3940256099942544/1033173712` |
| Android | `ca-app-pub-3940256099942544/1044960115` |

Replace with real IDs before store submission. See [docs/admob-setup.md](admob-setup.md) for full account setup.

---

## File Creation Order

### iOS
1. `GameState.swift`
2. `AnimationQueue.swift`
3. `GameLogic.swift`
4. `LayoutCalculator.swift`
5. `ScoreStore.swift`
6. `SoundEffect.swift`
7. `AudioManager.swift`
8. `AdManager.swift`
9. `FlowerRenderer.swift`
10. `GridRenderer.swift`
11. `SidebarRenderer.swift`
12. `VolumeControlView.swift`
13. `GameView.swift`
14. `ViewController.swift`
15. `SceneDelegate.swift` / `AppDelegate.swift`
16. `Info.plist` (add `GADApplicationIdentifier`)
17. `Podfile` → `pod install`

### Android
1. `GameState.kt`
2. `AnimationQueue.kt`
3. `GameLogic.kt`
4. `LayoutCalculator.kt`
5. `ScoreStore.kt`
6. `SoundEffectPool.kt`
7. `AudioManager.kt`
8. `AdManager.kt`
9. `FlowerRenderer.kt`
10. `GridRenderer.kt`
11. `SidebarRenderer.kt`
12. `VolumeControlView.kt`
13. `GameView.kt`
14. `MainActivity.kt`
15. `AndroidManifest.xml` (add App ID meta-data)
16. `build.gradle` (add AdMob dependency)
17. `google-services.json` (from AdMob/Firebase console)

---

## Verification Checklist

- [ ] All 7 flower types render with correct petal shapes (side-by-side with web version)
- [ ] Layout scales correctly on iPhone SE and iPad Pro 12.9" in both orientations
- [ ] `bfsReachable` from (0,0) on empty 9×9 board returns 80 cells
- [ ] `findLines` detects horizontal, vertical, and both diagonals
- [ ] `elasticOut(0.5) ≈ 1.276` (verifies bounce overshoot)
- [ ] MOVE animation slides smoothly along BFS path
- [ ] ELIMINATE shrinks + fades over 450ms
- [ ] SPAWN bounces in with elastic over 400ms
- [ ] BGM plays at 45% on first launch, loops, persists after force-quit
- [ ] SFX fires on: select, move, eliminate, game over
- [ ] Volume sliders change audio in real time; settings persist
- [ ] Game Over panel shows both buttons
- [ ] "Watch Ad & Play Again" → fullscreen ad → 3-2-1 countdown → Skip button → new game
- [ ] "Play Again" → new game immediately (no ad)
- [ ] Ad preloaded for second game over
- [ ] Rotation mid-game: layout recalculates, game state preserved, audio uninterrupted
