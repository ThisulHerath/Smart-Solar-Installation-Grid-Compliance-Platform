# Render, Vercel and Android release guide

This guide deploys the ASP.NET Core API and agentic AI service to Render, the
React/Vite site to Vercel, and produces an installable Flutter Android APK.

## 1. Before deploying

1. Push the repository and `render.yaml` to the GitHub default branch.
2. Create a production PostgreSQL database (the application is already set up
   for a Neon PostgreSQL connection string).
3. Create a Cloudinary account and note its cloud name, API key and API secret.
4. Decide whether this is a private university demonstration or a public
   launch. The database migrations contain public demo accounts documented in
   the README. Disable or replace them before a public launch.

Never commit `.env`, `key.properties`, a `.jks` file, database credentials or
provider secrets.

## 2. Deploy the backend services on Render

1. In Render, choose **New > Blueprint** and connect this GitHub repository.
2. Render detects the root `render.yaml`. Apply the Blueprint.
3. Enter the values requested for the API service:
   - `DATABASE_CONNECTION_STRING`: production PostgreSQL connection string.
   - `CORS_ALLOWED_ORIGINS`: the final Vercel origin, for example
     `https://smart-solar.example.vercel.app`. A temporary non-production URL
     can be used until Vercel assigns the real one.
   - `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`,
     `CLOUDINARY_API_SECRET`: production Cloudinary credentials.
4. For registration, password reset and account security emails on Render Free,
   configure the HTTPS provider: `EMAIL_PROVIDER=brevo-api`, `BREVO_API_KEY`,
   and a Brevo-verified `BREVO_FROM_EMAIL`. Render Free blocks outbound SMTP
   ports, so the `smtp` and `brevo` SMTP modes are intended for local or paid
   hosting environments where those ports are available.
5. Wait for both services to become healthy. Verify:
   `https://<render-api-host>/api/health`.

The Blueprint creates both the API and AI component as Free web services and
shares one generated `AGENTIC_AI_INTERNAL_KEY` between them. The AI service has
a public URL because Render's Free plan does not support private services, but
all workflow endpoints remain protected by the internal key. Only its health
endpoint is intentionally public.

## 3. Deploy the web app on Vercel

1. In Vercel, import the same GitHub repository.
2. Set **Root Directory** to `frontend-web`.
3. Select the Vite framework preset. The build command is `npm run build` and
   the output directory is `dist`.
4. Add the production environment variable:
   `VITE_API_BASE_URL=https://<render-api-host>` (do not add `/api`).
5. Deploy and copy the assigned HTTPS URL.
6. Return to the Render API environment and set `CORS_ALLOWED_ORIGINS` to that
   exact origin. Multiple origins must be comma-separated. Redeploy the API.
7. Test login, survey submission, photo upload, assignment, notifications,
   compliance evaluation, password reset and logout in the deployed site.

The checked-in `vercel.json` keeps React Router routes working after a browser
refresh.

## 4. Prepare Android release signing

Install Android SDK Command-line Tools (latest) from Android Studio's SDK
Manager, then run:

```powershell
flutter doctor
flutter doctor --android-licenses
```

Create an upload keystore once and keep it backed up securely:

```powershell
keytool -genkeypair -v -keystore frontend-mobile/android/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
Copy-Item frontend-mobile/android/key.properties.example frontend-mobile/android/key.properties
```

Replace all placeholders in `frontend-mobile/android/key.properties`. The
keystore and properties file are intentionally ignored by Git. Losing the key
can prevent future updates signed with the same identity.

## 5. Build and test the APK

From `frontend-mobile`, use the deployed Render API origin:

```powershell
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build apk --release --dart-define=API_BASE_URL=https://<render-api-host>
```

The universal APK is created at:

`frontend-mobile/build/app/outputs/flutter-apk/app-release.apk`

For smaller architecture-specific downloads, use:

```powershell
flutter build apk --release --split-per-abi --dart-define=API_BASE_URL=https://<render-api-host>
```

Install the APK on at least one real phone and verify login, camera/photo
upload, location permission, map directions, notifications and technician job
flows before sharing it.

## 6. Create a public APK download link

1. Open the GitHub repository and choose **Releases > Draft a new release**.
2. Create a version tag such as `v1.0.0`.
3. Attach `app-release.apk` as a release asset.
4. Publish the release and copy the asset's download URL.

For Play Store distribution, build the preferred Android App Bundle instead:

```powershell
flutter build appbundle --release --dart-define=API_BASE_URL=https://<render-api-host>
```

The result is `frontend-mobile/build/app/outputs/bundle/release/app-release.aab`.
