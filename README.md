
# **SentiaFlow: Your On-Device AI Wellness Coach**

[![Flutter](https://img.shields.io/badge/Made%20with-Flutter-%2302569B?logo=flutter)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Language-Dart-%230175C2?logo=dart)](https://dart.dev/)
[![Platform](https://img.shields.io/badge/Platform-Android-%233DDC84?logo=android)](https://www.android.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

[![AI Model](https://img.shields.io/badge/AI%20Model-Gemma%203n-%234285F4?logo=google)](https://ai.google.dev/gemma)
[![UI/UX](https://img.shields.io/badge/UI/UX-ScreenUtil-blueviolet)](https://pub.dev/packages/flutter_screenutil)
[![State Management](https://img.shields.io/badge/State%20Management-Provider-blue)](https://pub.dev/packages/provider)

SentiaFlow is a proactive, on-device wellness companion designed to bring sophisticated, AI-driven health analysis directly into the user's hands. It leverages Google's Gemma 3n to provide intelligent, private, and offline-first feedback on fitness and nutrition.

**This project is a submission for the [Google - The Gemma 3n Impact Challenge](https://www.kaggle.com/competitions/google-gemma-3n-hackathon).**

-----

## **🎥 Video Demo**
The video demo is available here and has already been integrated into the submission [video_demo_sentia_flow](https://youtu.be/nbQL5s7CbiE?si=ismssEVfFCnsPvlt)


## **✨ Key Features**

  * **ActiveFlow:** An AI-powered personal trainer that analyzes your exercise form from a single image (using additional context), and provides actionable coaching to improve posture and prevent injury.
  * **NourishFlow:** A hyper-personalized nutritionist that analyzes meal photos, identifies ingredients, and provides detailed health advice or meal plans based on your specific health data.
  * **100% On-Device:** All AI processing is handled by Gemma 3n directly on the user's device. No data is ever sent to a server.
  * **Privacy by Design:** User photos and sensitive health information never leave the phone, ensuring total privacy.
  * **Fully Offline:** Once the model is downloaded, the app's core features work perfectly without an internet connection.
  * **Engineered for Accessibility:** Optimized to run smoothly on entry-level Android devices, ensuring advanced AI is accessible to everyone.

## **🏛️ Technical Architecture & Stack**

SentiaFlow is built with Flutter and engineered for robustness and scalability. The architecture follows a clear separation of concerns.

#### **Core Technologies:**

  * **Framework:** Flutter
  * **AI Model:** Google Gemma 3n-E2B via implemented using `flutter_gemma` package.
  * **Pose Detection:** Google ML Kit (`google_mlkit_pose_detection`).
  * **State Management:** `provider` for dependency injection and `ValueNotifier` for granular state changes.
  * **Local Storage:** `shared_preferences` for user preferences and session management.

#### **Architectural Pattern:**

We adopted an **Orchestrator/Engineer** model:

  * **The Orchestrator (`main_shell.dart`):** The UI layer that knows *what* to do and *when*. It manages the application's flow based on the AI's state (e.g., showing a loading view, an error, or the main app).
  * **The Engineer (`gemma_service.dart`):** The core service layer that knows *how* to perform complex tasks. It handles everything related to the Gemma model—downloading, initialization, state management, and running inference—completely decoupled from the UI.

#### **State Management:**

The app's state is managed through a centralized state machine within `GemmaService`, defined by the `GemmaState` enum. This provides a single source of truth for the AI's lifecycle. `ValueNotifier`s are used to broadcast granular changes to the UI, ensuring performant and surgical updates without rebuilding entire screens. The UI for these states is handled by a dedicated set of widgets in `state_views.dart`.

## **🧠 Core AI Implementation**

My innovation lies in the fusion of multiple data sources to provide context-aware AI guidance.

### **ActiveFlow: From Landmarks to Meaning**

1.  **Data Extraction:** Google's ML Kit analyzes the user's photo to extract raw joint coordinates ("landmarks").
2.  **Data Processing:** Our `AngleCalculator` utility converts these raw coordinates into meaningful biomechanical angles (e.g., elbow angle, knee angle).
3.  **Multimodal Inference:** We feed Gemma two things at once: the **image** for visual context and the calculated **angles** as precise textual data. Gemma fuses what it *sees* with what it *knows* from the data to provide a single, insightful coaching tip.

### **NourishFlow: Hyper-Personalized Guidance**

1.  **Visual Analysis:** Gemma's vision capabilities are used to deconstruct a photo of a meal or raw ingredients, identifying the food items.
2.  **Contextual Fusion:** This visual data is then fused with a rich, user-provided textual profile, including health metrics (weight, blood pressure, glucose) and dietary preferences.
3.  **Personalized Output:** The prompt instructs Gemma to act as an expert nutritionist, using the combined visual and personal data to generate a hyper-personalized analysis or meal plan.

## **🚀 Getting Started**

To get a local copy up and running, follow these simple steps.

### **Prerequisites**

  * Flutter SDK: Make sure you have the Flutter SDK installed.
  * An Android device or emulator.

### **Installation**

1.  Clone the repo:
    ```sh
    git clone https://github.com/Abirate/Sentiaflow.git
    ```
2.  Navigate to the project directory:
    ```sh
    cd SentiaFlow
    ```
3.  Install dependencies:
    ```sh
    flutter pub get
    ```
4.  Run the app:
    ```sh
    flutter run
    ```

**Important:** The first time you run the app, you will be prompted to enter a **Hugging Face access token with read access**. This is required to download the Gemma 3n model.

## **🔮 Future Roadmap**

This is just the beginning. As the on-device AI ecosystem evolves, so will SentiaFlow:

  * **Real-Time Coaching:** With future support for video streams in `flutter_gemma`, ActiveFlow will evolve into a real-time coach for fitness and physical therapy.
  * **Mental Wellness Support:** With upcoming audio modality support, we plan to introduce a private, on-device companion for mental wellness, capable of analyzing sentiment and offering supportive feedback.

## **📜 License**

Distributed under the MIT License. See `LICENSE` for more information.

## **Acknowledgments**

  * Google for the powerful and accessible Gemma models.
  * The Flutter team and community.
  * [Google DeepMind] for this incredible opportunity.

## Getting Started with Flutter

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
