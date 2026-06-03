<p align="center">
  <img src="assets/icons/chowscan_app_icon.png" width="150" alt="ChowScan App Icon" />
</p>

<h1 align="center">ChowScan</h1>

<p align="center">
  <strong>Offline AI-powered food analysis & nutrition tracking.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.24%2B-02569B?style=for-the-badge&logo=flutter" alt="Flutter" />
  <img src="https://img.shields.io/badge/Gemma-On--Device-4285F4?style=for-the-badge&logo=google-gemini" alt="Gemma" />
  <img src="https://img.shields.io/badge/Dart-3.5%2B-0175C2?style=for-the-badge&logo=dart" alt="Dart" />
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS-3DDC84?style=for-the-badge&logo=android" alt="Android" />
  <img src="https://img.shields.io/badge/Storage-SharedPreferences-FF6F00?style=for-the-badge&logo=dart" alt="SharedPreferences" />
</p>

## Description

ChowScan is an offline AI-powered food analysis and nutrition tracking mobile application. It utilizes Google's Gemma model to execute full visual plate scans, nutrition label scans, and natural language descriptions entirely on-device, offering a private and self-contained nutrition tracking ecosystem.

## On-Device AI Engine (Gemma)

ChowScan is powered entirely by Google's **Gemma 4 E2B IT (LiteRT-LM)** model, which executes locally on your device via the `flutter_gemma` package:

- **Model Details**:
  - **Weights**: `gemma-4-E2B-it.litertlm` (~2.59GB) instruction-tuned.
  - **Runtime Format**: LiteRT-LM (optimized for mobile execution).
  - **Hardware Acceleration**: Automatically interfaces with the device GPU (`PreferredBackend.gpu`) to ensure swift and efficient response generation.

- **Capabilities Powered by Gemma**:
  - **Multimodal Scanning**: Processes camera frames of nutrition labels and meal plates directly as inputs to identify foods and extract text layout arrays.
  - **Structured Extraction**: Translates complex, arbitrary visual/textual data into structured JSON objects (representing Calories, Protein, Carbs, Fat, and micronutrients) that can be inserted into the database.
  - **Conversational Wellness Coaching**: Executes local context-aware text generation to power the in-app AI Chat screen, letting you ask follow-up questions about your meals with full visual support (attaching images) and message history persistence.

## Features

- **Scan a Label** - capture or select an image of a nutrition facts label to extract and analyze every macro and micronutrient offline.
- **Scan a Plate** - take a photo of your food to generate real-time estimates of calories and macronutrients.
- **Describe a Meal** - type a natural language description of what you ate to retrieve instant nutritional information.
- **Daily Intake Log** - view and manage your logged historical meals via a horizontal weekly date strip or choose past dates using the integrated calendar modal.
- **AI Chat** - converse with an on-device wellness coach to ask follow-up questions about logged foods, with full conversation history and image input support.
- **Onboarding Journey** - initialize personal details, target calorie goals, and food preferences.
- **Reactive Theming System** - fully supports system-wide and manual light/dark mode toggles across all pages, layouts, and custom cards.
- **Offline Security** - zero data leaves the user's phone, preserving complete privacy.

## Tech Stack

- **Flutter** - Cross-platform application framework for crafting high-performance user interfaces.
- **flutter_gemma** - On-device AI wrapper used to run the local Gemma multimodal large language model with hardware acceleration.
- **Provider** - Dynamic state management container to coordinate views and logic layers.
- **SharedPreferences** - Key-value persistent storage used to serialize user profiles and daily intake records locally.
- **Material 3** - System design specifying responsive dynamic color palettes for automated light and dark themes.
- **fl_chart & percent_indicator** - Graphing engines rendering interactive calorie rings and macro breakdowns.
- **flutter_animate** - Lightweight framework implementing page transitions and micro-interactions.

## System Architecture

The project is structured following a clean Model-View-ViewModel (MVVM) architecture:

- **Presentation Layer**: Built using Flutter with declarative Material 3 widgets. State is managed reactively via the Provider pattern, bridging UI views with underlying data viewmodels.
- **Business Logic Layer (ViewModels)**: Orchestrates local databases, handles input states, triggers AI analysis pipelines, and coordinates navigation workflows.
- **Service Layer**: 
  - `ModelManager`: Interacts with the local LLM engine.
  - `LocalDbService`: Persists user profiles and meal lists locally.
  - `ImageService`: Manages file paths for stored captured meal images.
- **Local Model Layer**: Integrates the raw multimodal Gemma weights directly on-device using a hardware-accelerated wrapper, executing visual and text queries offline.

## Project Structure

```
lib/
├── main.dart                # Application entry, router, and provider registration
├── theme/                   # Shared theme configuration, AppColors, and text styles
├── models/                  # Pure data structures (NutritionInfo, UserProfile, etc.)
├── services/                # Device service handlers (ModelManager, LocalDbService)
├── viewmodels/              # MVVM ViewModels separating business logic from widgets
└── views/
    ├── screens/             # Interactive UI pages (DailyIntakeScreen, SettingsScreen, etc.)
    └── widgets/             # Reusable UI widgets (CapturePromptCard, NutrientResultCard)
```

## Getting Started

### Prerequisites

- Flutter SDK (version 3.24.0 or higher)
- Android SDK or iOS Xcode configuration
- Minimum of 4GB storage available on the target physical device or emulator to accommodate the local model weights (approximately 2.6GB)

### Execution

Compile and launch the project locally using the following steps:

1. Clone or navigate to the source directory:
   ```bash
   cd flutter-app
   ```
2. Retrieve packages and dependencies:
   ```bash
   flutter pub get
   ```
3. Run the application:
   ```bash
   flutter run
   ```

*Note: On the first launch, the application will guide you to download the offline Gemma model weights over Wi-Fi. Once completed, no active network connection is required.*

## License

This project is licensed under the MIT License.
