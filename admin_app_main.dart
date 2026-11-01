name: Build School APKs

on:
  push:
    branches: [ main, master ]
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Set up Java 17
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '17'

      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          channel: 'stable'

      - name: Create Flutter project and add packages
        run: |
          flutter create --org com.maurischool app_project
          cd app_project
          flutter pub add http shared_preferences intl url_launcher
          sed -i '/<application/i <uses-permission android:name="android.permission.INTERNET"/>' android/app/src/main/AndroidManifest.xml

      - name: Build Teacher APK
        run: |
          cp user_app_main.dart app_project/lib/main.dart
          cd app_project
          sed -i 's/android:label="[^"]*"/android:label="تطبيق المعلم"/g' android/app/src/main/AndroidManifest.xml
          flutter build apk --release --no-tree-shake-icons
          cp build/app/outputs/flutter-apk/app-release.apk ../teacher-app.apk

      - name: Build Admin APK
        run: |
          cp admin_app_main.dart app_project/lib/main.dart
          cd app_project
          sed -i 's/android:label="[^"]*"/android:label="تطبيق المدير"/g' android/app/src/main/AndroidManifest.xml
          sed -i 's/applicationId "com.maurischool.app_project"/applicationId "com.maurischool.admin"/g' android/app/build.gradle* || true
          sed -i 's/applicationId = "com.maurischool.app_project"/applicationId = "com.maurischool.admin"/g' android/app/build.gradle* || true
          flutter build apk --release --no-tree-shake-icons
          cp build/app/outputs/flutter-apk/app-release.apk ../admin-app.apk

      - name: Upload APKs
        uses: actions/upload-artifact@v4
        with:
          name: Mauri-School-APKs
          path: |
            teacher-app.apk
            admin-app.apk
            
