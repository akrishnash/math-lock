# Publish Earn Your Screen to Google Play Store

## 1. Google Play Developer account

- Go to [Google Play Console](https://play.google.com/console).
- Sign in with a Google account and pay the **one-time $25** registration fee.
- Accept the developer distribution agreement.

## 2. Create a release keystore (one-time)

Run this in a terminal (replace `YOUR_PASSWORD` and keep it safe):

```bash
cd android
keytool -genkey -v -keystore upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

- **Keystore password** and **key password**: use a strong password; store it somewhere safe (e.g. password manager).
- **First and last name**: your name or company.
- **Organizational unit / Organization / City / State / Country**: fill as needed.

**Important:** Back up `upload-keystore.jks` and the passwords. If you lose them, you cannot update the app on Play Store.

## 3. Configure signing

Create `android/key.properties` (this file is gitignored):

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=upload-keystore.jks
```

Use the same passwords and alias you used when creating the keystore. `storeFile` is relative to the `android/` folder.

## 4. Build the release app bundle

From the project root:

```bash
./scripts/build_release.sh
```

Or manually:

```bash
flutter build appbundle --release
```

Output:

- **`build/app/outputs/bundle/release/app-release.aab`**

Google Play prefers **AAB** (Android App Bundle) over APK for smaller downloads.

## 5. Create the app in Play Console

1. In [Play Console](https://play.google.com/console) → **Create app**.
2. **App name:** Earn Your Screen  
3. **Default language**, **App or game**, **Free or paid** as needed.

## 6. Complete required setup

In Play Console, finish all required sections for your first release:

| Section | What to do |
|--------|------------|
| **App content** → **Privacy policy** | Add a URL to your privacy policy (required if you collect data, e.g. Firebase Auth). |
| **App content** → **Ads** | Declare if the app contains ads (Earn Your Screen: No, unless you add them). |
| **App content** → **App access** | If all features require login, provide a test account or state that no login is required for core features. |
| **App content** → **Content rating** | Fill the questionnaire (e.g. “Utility” / no sensitive content) and submit. |
| **App content** → **Target audience** | Set age groups (e.g. 13+ or 18+). |
| **App content** → **News app** | Select “No” unless it’s a news app. |
| **Release** → **Production** (or **Testing**) | Create a new release and upload `app-release.aab`. |
| **Store listing** | Short and full description, screenshots (phone 16:9 or 9:16, min 2), feature graphic 1024×500, app icon 512×512. |

## 7. Upload the AAB and publish

1. **Release** → **Production** (or **Testing** → **Internal testing** to test first).
2. **Create new release** → upload **`build/app/outputs/bundle/release/app-release.aab`**.
3. Add **Release name** (e.g. “1.0.0 (1)”) and optional release notes.
4. **Review release** → **Start rollout to Production** (or save for internal testing).

After review, the app will go live (or appear in the chosen testing track).

## 8. Later updates

- Bump **version** in `pubspec.yaml` (e.g. `version: 1.0.1+2` — name and build number must increase).
- Run `./scripts/build_release.sh` again and upload the new AAB to a new release in the same track.

## Quick reference

| Item | Location |
|------|----------|
| Release AAB | `build/app/outputs/bundle/release/app-release.aab` |
| Signing config | `android/app/build.gradle.kts` (reads `android/key.properties`) |
| Keystore | `android/upload-keystore.jks` (create once; back up) |
| Version | `pubspec.yaml` → `version: 1.0.0+1` |
