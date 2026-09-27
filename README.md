# 🏠 House Vision: Spatial 3D & Augmented Reality Construction Coordination

> **College Project — Semester 5 CCP / MAD (Mobile Application Development)**  
> *Bridging Architectural BIM, On-Site Computer Vision Verification, and Augmented Reality*

---

## 📌 Repository Overview

This repository contains the complete codebase and architecture for **House Vision**, structured into two iterative versions alongside ready-to-install Android APKs:

```
college_project_housevision/
├── apks/                               # Pre-compiled Android application packages (APKs)
│   ├── house_vision_v1.apk             # Baseline v1 APK (compiled & installable)
│   └── house_vision_v2.apk             # Next-gen v2 Prototype APK (compiled & installable)
│
├── v1/                                 # Baseline Version 1 Architecture (Concept)
│   └── application/                    # Early prototype Flutter application
│       ├── lib/                        # Early prototype screens, AR viewer & models
│       ├── android/                    # Cleaned Android Gradle build configuration
│       └── pubspec.yaml                # v1 package dependencies
│
├── v2/                                 # Next-Generation Version 2 Architecture (Production Prototype)
│   └── application/                    # Modern layered Flutter application
│       ├── lib/
│       │   ├── core/                   # Architectural Dark Studio theme, HUD telemetry atoms
│       │   ├── domain/                 # Domain entities, ML inspection models, repository contracts
│       │   ├── data/                   # BimVisionAiEngine (on-device ML & CV), Firebase services
│       │   └── presentation/           # Main navigation dock, AI Vision Lab, AR Projector, 3D Studio
│       ├── test/                       # Unit tests & smoke tests (100% passing)
│       └── pubspec.yaml                # Clean modern dependencies & asset mappings
│
├── .gitattributes                      # Git LFS tracking rules for 3D binary models (.glb)
├── .gitignore                          # Standardized exclusion rules for Dart, Flutter, Gradle & IDEs
└── README.md                           # Master project documentation
```

---

## 🚀 Key Feature Comparison: v1 vs v2

| Feature Area | Baseline v1 | Next-Gen v2 Prototype |
|---|---|---|
| **Architecture** | Flat MVC / Screen-driven | Layered Clean Architecture (MVVM + Repository Pattern) |
| **Design Language** | Standard Material Light theme | **Architectural Dark Studio** (`#0B0F19`, `#06B6D4`, `#F59E0B`) |
| **Telemetry HUD** | None | Live GPS telemetry, compass bearing with micro-drift, LiDAR lock |
| **Computer Vision / ML** | Not implemented | **`BimVisionAiEngine`**: 4x4 spatial gradient matrix, 4 site presets |
| **Reality Verification** | Static screenshot viewer | **Interactive Split-Curtain swipe slider** with live laser scan |
| **AR Tools** | Basic model projection | **Virtual Laser Tape Measure** with 3D Euclidean distance vector |
| **Sun & Shadow Study** | Fixed lighting | **Heliodon solar simulation slider** (07:00 to 18:00) |
| **3D BIM Customization** | Position slider | Layer toggles (Structure/MEP/Envelope), materials, real-time cost estimate |
| **Test Coverage** | Smoke test only | 10 unit and widget test suites (ML engine, models, UI) |

---

## 📦 Installed Libraries & Git Exclusions

To keep the repository clean and avoid committing gigabytes of cache and generated files, the root `.gitignore` excludes all files that can be installed or regenerated on demand:

### What is Excluded from Git (and can be re-installed):
1. **`.dart_tool/` & `.flutter-plugins-dependencies`**:
   - Re-generated automatically by running `flutter pub get`.
2. **`build/` & `android/app/build/`**:
   - Re-generated automatically during compilation with `flutter build apk` or `flutter run`.
3. **`android/.gradle/`**:
   - Local Gradle cache and downloaded dependencies; re-downloaded automatically by Gradle.
4. **`android/local.properties`**:
   - Machine-specific configuration pointing to your local Android SDK and Flutter SDK paths.
5. **`apks/` (`*.apk`, `*.aab`)**:
   - Built Android application packages are ~350MB each. GitHub rejects individual files over 100MB; APKs should be shared via **GitHub Releases** or installed directly from your local `apks/` directory.
6. **`.idea/`, `*.iml`, `.vscode/`**:
   - IDE configuration files specific to local developer environments.

---

## 🛠️ Step-by-Step Git Upload Instructions

This repository is pre-configured and ready to be pushed to your GitHub repository:
**`https://github.com/sangrechy/college_project_house_vision.git`**

### 1. Open Terminal at the Project Root
```powershell
cd E:\PROJECTS\college_project_housevision
```

### 2. Initialize Git Repository
```powershell
git init
```

### 3. Configure Git LFS (for 3D `.glb` assets)
```powershell
git lfs install
git lfs track "*.glb"
git add .gitattributes
```

### 4. Stage and Commit Source Files
```powershell
git add .
git commit -m "feat: complete House Vision v1 baseline and v2 dark studio prototype with ML vision and AR"
```

### 5. Link GitHub Remote and Push
```powershell
git branch -M main
git remote add origin https://github.com/sangrechy/college_project_house_vision.git
git push -u origin main
```

---

## 📱 How to Run or Install

### Option A: Install Pre-Built APKs directly to Device / Emulator
Connect your Android phone (or launch your emulator) and run:
```powershell
# To install v2 (Recommended prototype):
adb install -r E:\PROJECTS\college_project_housevision\apks\house_vision_v2.apk

# To install v1 (Baseline):
adb install -r E:\PROJECTS\college_project_housevision\apks\house_vision_v1.apk
```

### Option B: Run from Source via Flutter CLI

#### Running v2 (Prototype):
```powershell
cd E:\PROJECTS\college_project_housevision\v2\application
flutter pub get
flutter run
```

#### Running v1 (Baseline):
```powershell
cd E:\PROJECTS\college_project_housevision\v1\application
flutter pub get
flutter run
```

---

## 🧪 Automated Testing & Static Analysis

Both versions have been verified with 0 build errors:

```powershell
# Analyze and test v2:
cd E:\PROJECTS\college_project_housevision\v2\application
flutter analyze
flutter test

# Analyze and test v1:
cd E:\PROJECTS\college_project_housevision\v1\application
dart analyze
flutter test
```
