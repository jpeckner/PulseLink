# Learning log

What I learned per milestone, with Flutter-vs-native notes.

## Milestone 1: Setup and skeleton (2026-11-11)

Built: Flutter 3.50.0 project (iOS + Android), bundle ID `com.jpeckner.pulselink`,
layered folders, `very_good_analysis` lints, `flutter_bloc`, a smoke widget test
and a GitHub Actions workflow (format, analyze, test).

Flutter vs native:

- **`flutter create` gives you two real native projects.** `ios/` is a normal
  Xcode workspace and `android/` a normal Gradle project. Signing, `Info.plist`,
  Android permissions, and later the watchOS target all live there.
- **`pubspec.yaml` + `pubspec.lock`** play the role of `Package.swift` +
  `Package.resolved` (or a Gradle version catalog + lockfile). `^9.1.1` means
  "up to the next major version", like SPM's `.upToNextMajor(from:)`.
- **Material is a package now.** Since Flutter 3.47, `package:flutter/material.dart`
  is deprecated in favor of `package:material_ui`. The core
  `package:flutter/widgets.dart` stays in the SDK, similar to how Compose splits
  `foundation` from `material3`.
- **`StatelessWidget.build()`** is SwiftUI's `body` or a `@Composable` function
  with no state. Widgets are cheap, immutable descriptions; the framework diffs them.
- **`const` constructors** create compile-time canonical instances, so Flutter can
  skip rebuilding those subtrees. The linter pushes `const` everywhere for this reason.
- **Dart 3.14 constructors** can be written `const new({super.key});` instead of
  repeating the class name, much like Swift's `init`.
- **No CocoaPods.** Flutter now resolves iOS plugin code with Swift Package
  Manager: it generates a local `FlutterGeneratedPluginSwiftPackage` that the
  Runner target links, much like adding a local package in Xcode. The project
  pins this with `flutter: config: enable-swift-package-manager: true` in
  `pubspec.yaml`. `flutter doctor` still checks for CocoaPods on every Mac,
  so its warning there is harmless for this project.
- **`analysis_options.yaml`** is like a SwiftLint or detekt config, but the
  analyzer ships with the SDK, so lints show inline in the IDE and fail CI via
  `flutter analyze`.
- **`BlocObserver`** is a global hook on every Bloc/Cubit state change, like a
  Redux middleware. It will feed the in-app debug log in Milestone 4.

Regulated-app note: the Flutter SDK version (in CI) and the lint rule set (in
`analysis_options.yaml`) are both pinned. A regulated team would record every
third-party component and version as SOUP under IEC 62304.
