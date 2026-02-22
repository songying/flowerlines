# AdMob Setup Guide for Flower Lines

This guide walks you through setting up Google AdMob to display interstitial ads in the Flower Lines iOS and Android apps, and how to start earning revenue.

---

## Overview

**AdMob** is Google's mobile advertising platform. For Flower Lines, we use **Interstitial ads** — fullscreen ads shown after each game on the Game Over screen.

Revenue model: you earn money each time a user views or clicks an ad. With a casual game, CPM (cost per 1,000 impressions) typically ranges from $1–$5 USD depending on region and traffic volume.

---

## Step 1: Create an AdMob Account

1. Go to **https://admob.google.com**
2. Sign in with a Google account (create one if needed)
3. Click **Get Started**
4. Fill in your country and timezone
5. Agree to the Terms of Service

> **Payment profile required to receive earnings:**
> After signing up, go to **Payments → Add payment method** and enter your bank account or PayPal details. AdMob pays out monthly when your balance exceeds $100 USD.

---

## Step 2: Add Your Apps

You need to add both the iOS and Android versions separately.

### iOS App

1. In the AdMob console, go to **Apps → Add App**
2. Platform: **iOS**
3. "Is the app listed on a supported app store?" → Select **No** (until you publish)
4. App name: `Flower Lines`
5. Click **Add**
6. Copy your **App ID** — format: `ca-app-pub-XXXXXXXX~XXXXXXXXXX`
   - The `~` separates the publisher ID from the app ID

### Android App

Repeat the same steps:
1. **Apps → Add App**
2. Platform: **Android**
3. Not listed yet → **No**
4. App name: `Flower Lines`
5. Copy the **App ID** (different from the iOS one)

---

## Step 3: Create Ad Units

For each app, create an Interstitial ad unit.

### For iOS App

1. Select your iOS Flower Lines app in the console
2. Go to **Ad Units → Add Ad Unit**
3. Select **Interstitial**
4. Ad unit name: `Game Over Interstitial`
5. Click **Create Ad Unit**
6. Copy the **Ad Unit ID** — format: `ca-app-pub-XXXXXXXX/XXXXXXXXXX`
   - The `/` separates the publisher ID from the unit ID

### For Android App

Repeat for your Android app — you'll get a different Ad Unit ID.

---

## Step 4: Configure Your Apps

### iOS — `Info.plist`

Add this key to `ios/FlowerLines/Info.plist`:

```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-XXXXXXXX~XXXXXXXXXX</string>
```

Replace the placeholder with your actual iOS **App ID** (with `~`).

Also add the SKAdNetwork identifiers (required for iOS 14+):

```xml
<key>SKAdNetworkItems</key>
<array>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>cstr6suwn9.skadnetwork</string>
  </dict>
  <!-- Google provides a full list at: https://developers.google.com/admob/ios/privacy/skadnetwork -->
</array>
```

### Android — `AndroidManifest.xml`

Add inside the `<application>` tag:

```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-XXXXXXXX~XXXXXXXXXX"/>
```

Replace the placeholder with your actual Android **App ID**.

---

## Step 5: Insert Ad Unit IDs into Code

### iOS — `AdManager.swift`

```swift
// Replace this:
private let adUnitID = "ca-app-pub-3940256099942544/1033173712"  // test ID
// With your real ID:
private let adUnitID = "ca-app-pub-XXXXXXXX/XXXXXXXXXX"
```

### Android — `AdManager.kt`

```kotlin
// Replace this:
private val adUnitId = "ca-app-pub-3940256099942544/1044960115"  // test ID
// With your real ID:
private val adUnitId = "ca-app-pub-XXXXXXXX/XXXXXXXXXX"
```

---

## Step 6: Test During Development

**Always use test ad IDs while developing.** Using real ad IDs during testing can get your AdMob account suspended for invalid traffic.

### Official Test Ad Unit IDs

| Platform | Format | Test Ad Unit ID |
|----------|--------|-----------------|
| iOS | Interstitial | `ca-app-pub-3940256099942544/1033173712` |
| Android | Interstitial | `ca-app-pub-3940256099942544/1044960115` |

Test ads look identical to real ads but generate no revenue and no invalid-traffic flags.

### Enable Test Devices (alternative)

You can also register your physical device as a test device so real ad IDs show test ads:

**iOS:** Add to `AppDelegate.swift`:
```swift
GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = [
    "YOUR_DEVICE_HASHED_ID"  // printed in Xcode console on first launch
]
```

**Android:** Add to `MainActivity.kt`:
```kotlin
MobileAds.initialize(this)
val config = RequestConfiguration.Builder()
    .setTestDeviceIds(listOf("YOUR_DEVICE_HASHED_ID"))  // in Logcat on first launch
    .build()
MobileAds.setRequestConfiguration(config)
```

---

## Step 7: Initialize AdMob SDK at App Launch

### iOS — `AppDelegate.swift`

```swift
import GoogleMobileAds

func application(_ application: UIApplication,
                 didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    GADMobileAds.sharedInstance().start(completionHandler: nil)
    return true
}
```

### Android — `MainActivity.kt`

```kotlin
import com.google.android.gms.ads.MobileAds

override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    MobileAds.initialize(this) { /* SDK ready */ }
    // ... rest of setup
}
```

---

## Step 8: Before App Store / Play Store Submission

1. **Switch from test IDs to real IDs** in `AdManager.swift` / `AdManager.kt`
2. **iOS App Store:** In your AdMob console, update the app listing to link to your App Store URL after publication
3. **Google Play:** Same — link to your Play Store URL
4. **IDFA (iOS):** Add App Tracking Transparency (ATT) prompt if targeting iOS 14.5+:
   ```swift
   import AppTrackingTransparency
   ATTrackingManager.requestTrackingAuthorization(completionHandler: { _ in })
   ```
   Add to `Info.plist`:
   ```xml
   <key>NSUserTrackingUsageDescription</key>
   <string>This identifier is used to deliver personalized ads to you.</string>
   ```

---

## Policy Compliance

### COPPA (Children's Privacy — US)
If your app targets children under 13, you must flag all ad requests as child-directed:

**iOS:**
```swift
let request = GADRequest()
request.tagForChildDirectedTreatment(true)
```

**Android:**
```kotlin
val config = RequestConfiguration.Builder()
    .setTagForChildDirectedTreatment(RequestConfiguration.TAG_FOR_CHILD_DIRECTED_TREATMENT_TRUE)
    .build()
MobileAds.setRequestConfiguration(config)
```

### GDPR (EU Users)
If you have EU users, you should show a consent dialog before showing ads. Google provides the **User Messaging Platform (UMP) SDK** for this:
- iOS: [Consent SDK for iOS](https://developers.google.com/admob/ios/privacy)
- Android: [Consent SDK for Android](https://developers.google.com/admob/android/privacy)

For a casual game with minimal EU traffic, you may initially skip this and add it if you notice EU users in your analytics.

---

## Revenue Expectations

| Metric | Typical range |
|--------|--------------|
| Interstitial fill rate | 70–95% |
| Interstitial CPM | $1–$8 USD (varies by country) |
| Revenue per 1,000 games | $0.70–$7.60 |

Factors that increase revenue: US/EU audience, high session count per user, good ad load time.

AdMob pays out monthly via direct bank transfer or wire transfer. Minimum payout threshold: $100 USD.

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Ad not loading | Check internet connection; verify App ID in manifest; use test IDs |
| `GADApplicationIdentifier` missing crash | Add the key to `Info.plist` before calling any SDK code |
| No ads showing in production | Wait 24–48h after publishing — AdMob needs to crawl your app |
| Account suspended | Ensure you never click your own ads; always use test IDs during dev |
| Low fill rate | Normal in some regions; ad fill improves as app gets more traffic |

---

## Quick Reference

```
AdMob Console:    https://admob.google.com
iOS SDK docs:     https://developers.google.com/admob/ios
Android SDK docs: https://developers.google.com/admob/android
Test IDs:         https://developers.google.com/admob/ios/test-ads
SKAdNetwork list: https://developers.google.com/admob/ios/privacy/skadnetwork
UMP SDK (GDPR):   https://developers.google.com/admob/ios/privacy
AdSense Console:  https://adsense.google.com
```

---

## Web Version (index.html) — Google AdSense

The web game hosted on GitHub Pages uses **Google AdSense** (not AdMob) for display ads. AdSense is Google's web advertising product and requires a separate account from AdMob.

### Ad Placement

Two **160×600 "Wide Skyscraper"** ad columns are placed on the left and right sides of the game canvas. They are hidden automatically via CSS `@media` query on screens narrower than 1020px, so the game layout is never affected on mobile or small windows.

```
┌──────────┬───────────────────────────┬──────────┐
│          │      🌸 Flower Lines 🌸    │          │
│  160×600 │  ┌─────────────────────┐  │  160×600 │
│  AdSense │  │    Game Canvas      │  │  AdSense │
│    ad    │  │    634 × 564 px     │  │    ad    │
│          │  └─────────────────────┘  │          │
└──────────┴───────────────────────────┴──────────┘
  hidden on screens < 1020px wide
```

### Step 1: Create a Google AdSense Account

1. Go to **https://adsense.google.com**
2. Sign in with a Google account
3. Enter your website URL (e.g. `https://yourusername.github.io/flowerlines`)
4. Select your country and agree to Terms of Service
5. Add the AdSense verification `<script>` tag to `index.html` and wait for site approval (typically 1–3 days)

> AdSense requires your site to have original content and comply with their policies before approval.

### Step 2: Create Ad Units

1. In AdSense console → **Ads → By ad unit → Display ads**
2. Create two units (one for left column, one for right — or reuse the same unit ID in both slots)
3. Ad size: **160 × 600** (Wide Skyscraper) or **Responsive**
4. Copy the generated `data-ad-client` (Publisher ID) and `data-ad-slot` values

### Step 3: Replace Placeholder Values in index.html

Search for all occurrences of `ca-pub-XXXXXXXXXXXXXXXX` and `XXXXXXXXXX` in `index.html` and replace:

```html
<!-- AdSense script tag (near </body>) -->
<script async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=ca-pub-XXXXXXXXXXXXXXXX"
   crossorigin="anonymous"></script>

<!-- Each ad slot <ins> element -->
<ins class="adsbygoogle"
     style="display:inline-block;width:160px;height:600px"
     data-ad-client="ca-pub-XXXXXXXXXXXXXXXX"
     data-ad-slot="XXXXXXXXXX"></ins>
```

Replace:
- `ca-pub-XXXXXXXXXXXXXXXX` → your **Publisher ID** from AdSense (format: `ca-pub-1234567890123456`)
- `data-ad-slot="XXXXXXXXXX"` → your **Ad Unit ID** (format: `1234567890`)

There are **3 places** to replace: the `<script>` src URL, and the two `<ins>` elements (left + right columns).

### Step 4: Push to GitHub Pages

```bash
git add index.html
git commit -m "Add real AdSense publisher and ad unit IDs"
git push origin main
```

GitHub Pages will redeploy automatically. Ads typically start appearing within a few hours of AdSense account approval.

### AdSense vs AdMob Comparison

| | AdSense (Web) | AdMob (iOS/Android) |
|---|---|---|
| Platform | Websites / GitHub Pages | Native mobile apps |
| Account | adsense.google.com | admob.google.com |
| Ad format | Display banners (160×600) | Interstitial (fullscreen) |
| Integration | `<script>` + `<ins>` tags | SDK via CocoaPods / Gradle |
| Revenue | CPM $0.50–$3 (varies) | CPM $1–$8 (varies) |

> Both accounts can be linked to the same Google account for unified reporting in Google Ad Manager.
