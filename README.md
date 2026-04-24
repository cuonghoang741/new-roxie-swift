# Roxie Swift

Bản port SwiftUI của app Roxie (React Native Expo ở `../roxie-native`). Bundle ID: `com.eduto.roxieswift`. App display name: **Roxie Swift**.

## Yêu cầu
- Xcode 16+ (đã test với Xcode 26.3)
- iOS 17+ (deployment target)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`) — dùng để regenerate `Roxie.xcodeproj` khi sửa `project.yml`

## Build + Run

```bash
# Tạo Xcode project (lần đầu hoặc sau khi chỉnh project.yml)
xcodegen generate

# Resolve SPM packages
xcodebuild -resolvePackageDependencies -project Roxie.xcodeproj -scheme Roxie

# Build cho simulator
xcodebuild -project Roxie.xcodeproj -scheme Roxie \
  -destination 'platform=iOS Simulator,name=iPhone 16e' -configuration Debug build

# Install + launch
xcrun simctl install booted \
  "$(find ~/Library/Developer/Xcode/DerivedData -name Roxie.app -path '*Debug-iphonesimulator*' -print | head -1)"
xcrun simctl launch booted com.eduto.roxieswift
```

Cũng có thể mở `Roxie.xcodeproj` bằng Xcode rồi bấm Run.

## Cấu trúc

```
roxie-swift/
├── project.yml                 # XcodeGen config
├── Roxie.xcodeproj/            # generated
└── Roxie/
    ├── RoxieApp.swift          # @main entry + AppDelegate
    ├── Info.plist
    ├── Roxie.entitlements      # Sign in with Apple
    ├── Config/AppConfig.swift
    ├── Models/                 # Character, Background, Costume, Dance, Quest, …
    ├── Services/
    │   ├── SupabaseService.swift       # client + X-Client-Id header
    │   ├── AuthManager.swift           # Apple + Google + email auth
    │   ├── AnalyticsService.swift
    │   ├── BackgroundMusicManager.swift
    │   ├── ChatService.swift
    │   ├── VoiceCallService.swift
    │   ├── CommercialSDKStubs.swift    # OneSignal/AppsFlyer/Firebase stubs
    │   └── UserPreferencesService.swift
    ├── Repositories/           # BaseRepository + CatalogRepositories + UserRepositories
    ├── Utils/                  # WebSceneBridge, Persistence, ClientIdStore, Logger
    ├── Theme/Palette.swift
    ├── ViewModels/             # VRMContext, AppRootModel
    ├── Views/
    │   ├── RootView.swift              # auth/onboarding/experience gating
    │   ├── Auth/SignInScreen.swift
    │   ├── Onboarding/                 # ImageOnboarding, OnboardingV2, NewUserGift
    │   ├── Character/CharacterPreviewScreen.swift
    │   ├── Subscription/SubscriptionScreen.swift
    │   ├── Sheets/CatalogSheets.swift
    │   ├── VRM/
    │   │   ├── VRMWebView.swift
    │   │   ├── VRMUIOverlay.swift
    │   │   └── VRMExperienceScreen.swift
    │   └── Common/                     # LiquidGlass, HapticButton, CurrencyBadge
    └── Resources/
        ├── index.html              # Three.js/VRM scene (94KB, copy từ bản RN)
        └── *.png / *.svg icons
```

## Ngôn ngữ

App hỗ trợ **5 ngôn ngữ**: English, Tiếng Việt, 日本語, Français, 한국어.

- Strings ở `Roxie/Localization/<lang>.lproj/Localizable.strings`
- Truy cập qua `L10n.someKey` enum (`Roxie/Localization/L10n.swift`) — đổi key là compile error chứ không rơi lặng xuống key raw
- User đổi ngôn ngữ trong-app: SignInScreen (nút globe góc phải) và SettingsSheet → chọn → app auto-restart với `AppleLanguages` đã set
- Auto-detect theo device locale lần đầu mở app

## Điều đã port

| Tính năng | Trạng thái |
|-----------|------------|
| Xcode project skeleton + bundle ID mới | ✅ |
| Đa ngôn ngữ EN/VI/JA/FR/KO | ✅ |
| Supabase client với `X-Client-Id` header cho guest | ✅ (supabase-swift 2.44) |
| BaseRepository + 13 repository (Character, Background, Costume, Currency, Dance, Quest, Relationship, LoginReward, Media, Subscription, Transaction, UserStats, Asset) | ✅ |
| AuthManager (Apple Sign-In + Google OAuth + email) | ✅ |
| VRMWebView (WKWebView) + WebSceneBridge JS (setCallMode, applyParallax, triggerDance, stopAction, loadAnimationByName, setMouthOpen, loadModel) | ✅ |
| Inject `window.nativeSelectedModelName/URL`, `initialBackgroundUrl`, `discoveredFiles` atDocumentStart | ✅ |
| Persistence (UserDefaults map giống RN AsyncStorage) | ✅ |
| SignIn với age verification + legal links + Safari webview | ✅ |
| ImageOnboarding, NewUserGift, OnboardingV2 | ✅ |
| CharacterPreviewScreen, SubscriptionScreen | ✅ |
| VRMExperienceScreen + VRMUIOverlay (level, streak, energy, currency badges) | ✅ |
| Sheets: Character / Background / Costume (grid + thumbnail) | ✅ |
| Quest / Energy / Level / Streak / Ruby sheet (placeholder card) | 🟡 |
| SettingsSheet (tài khoản, sign-out, link pháp lý) | ✅ |
| ChatService (Supabase `conversation` + `gemini-chat` edge function) | ✅ |
| ChatManager (Observable state, send flow, multi-message streaming với typing delay) | ✅ |
| Chat UI: ChatBottomOverlay, ChatInputBar, ChatMessageBubble, TypingIndicator, ChatHistoryModal | ✅ |
| VoiceCallService | 🟡 stub (chờ LiveKit/ElevenLabs iOS SDK) |
| Haptics | ✅ |
| BackgroundMusicManager (AVAudioPlayer) | ✅ (chờ `bgm.mp3` bundled) |

## SDK thương mại — chờ wire

`Services/CommercialSDKStubs.swift` chứa stub cho 5 SDK. Cần account/config riêng nên tôi để trống — app chạy bình thường trên simulator, khi lên production thay stub bằng SDK thật:

| SDK | Stub | Cách wire |
|-----|------|-----------|
| RevenueCat | `RevenueCatManager` | SPM `PurchasesKit`, `Purchases.configure(...)` trong `AppDelegate` |
| OneSignal | `OneSignalService` | SPM `OneSignalFramework`, app ID `52139459-74d3-47a7-9f5c-80e07e93265c` |
| Firebase | `FirebaseService` | SPM `firebase-ios-sdk`, copy `GoogleService-Info.plist` |
| AppsFlyer | `AppsFlyerService` | SPM `AppsFlyerLib` |
| Facebook SDK | `FacebookService` | SPM `facebook-ios-sdk` |
| LiveKit | `VoiceCallService` | SPM `client-sdk-swift` |
| ElevenLabs | — | `elevenlabs-swift-sdk` |
| TikTok Pixel | `TikTokService` | `TikTokBusinessSDK` (CocoaPods) |

## Env vars

`AppConfig.swift` đọc env var, fallback sang default (Supabase của bản RN):

- `SUPABASE_URL` — mặc định `https://cjtghurczxqheqwegpiy.supabase.co`
- `SUPABASE_ANON_KEY` — embed sẵn

Đặt qua Xcode scheme → Run → Environment Variables.

## Luồng app (RootView)

```
hasRestoredSession? ─┬─ no  → launchView (gradient + spinner)
                    └─ yes
                        │
             session? + clientId?
                    │
                    ├─ cả 2 đều null → SignInScreen
                    ├─ chưa xem image onboarding → ImageOnboardingScreen
                    ├─ isNewUser && chưa claim gift → NewUserGiftScreen
                    ├─ có session && chưa onboard V2 → OnboardingV2Screen
                    └─ → VRMExperienceScreen
```

Key `UserDefaults`:
- `persist.hasSeenImageOnboarding`
- `persist.hasClaimedNewUserGift`
- `persist.hasCompletedOnboardingV2`
- `persist.ageVerified18`
- `persist.characterId`, `persist.modelName`, `persist.modelURL`
- `persist.backgroundURL`, `persist.backgroundName`

## Ghi chú

- **Scene đen nếu không có character thực:** Three.js canvas chỉ render khi `window.nativeSelectedModelURL` trỏ vào file `.vrm` hợp lệ. Khi DB trả về characters có `base_model_url`, character đầu tiên được auto-chọn → model render. Trên simulator thử rỗng, overlay vẫn hoạt động đầy đủ — giống hệt hành vi RN.
- **Google Sign-In qua `ASWebAuthenticationSession`:** deep link `roxieswift://auth/callback` đã khai báo trong `Info.plist`.
- **Apple Sign-In entitlement:** có sẵn trong `Roxie.entitlements`.
- **HTML bundle:** `Roxie/Resources/index.html` copy từ `roxie-native/src/assets/html/index.html`. Regenerate bên RN (`node scripts/generateHtmlContent.js`) rồi `cp` lại khi có thay đổi.
