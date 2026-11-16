plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("dev.detekt")
}

android {
    namespace = "com.jpeckner.pulselink"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Release's id and name. Debug and profile add a suffix and a name of
        // their own (see buildTypes), so all three can be installed on one
        // phone at once, as on iOS.
        applicationId = "com.jpeckner.pulselink"
        manifestPlaceholders["appName"] = "PulseLink"
        manifestPlaceholders["appIcon"] = "@mipmap/ic_launcher"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // Android 12, the first version with the BLUETOOTH_SCAN and
        // BLUETOOTH_CONNECT permissions. Older versions also need location
        // permission, and location services switched on, to scan.
        minSdk = 31
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        debug {
            applicationIdSuffix = ".debug"
            manifestPlaceholders["appName"] = "PulseLink Debug"
            // An adaptive icon on light grey (src/debug/res).
            manifestPlaceholders["appIcon"] = "@mipmap/ic_launcher_build"
        }
        // The Flutter Gradle plugin creates the profile build type.
        getByName("profile") {
            applicationIdSuffix = ".profile"
            manifestPlaceholders["appName"] = "PulseLink Profile"
            // An adaptive icon on green (src/profile/res).
            manifestPlaceholders["appIcon"] = "@mipmap/ic_launcher_build"
        }
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Pigeon's generated Kotlin runs async calls (`@async` in
    // pigeons/ble_api.dart) with coroutines.
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.11.0")
    testImplementation("junit:junit:4.13.2")
}

// Lints the hand-written Kotlin; see android/config/detekt.yml and
// tool/lint_native.sh.
detekt {
    config.setFrom(rootProject.file("config/detekt.yml"))
    // Only the rules turned on in detekt.yml run.
    buildUponDefaultConfig = false
}

tasks.withType<dev.detekt.gradle.Detekt>().configureEach {
    // Pigeon's generated code (see pigeons/ble_api.dart).
    exclude("**/*.pigeon.kt")
}

// The native-code rule bans unchecked `as` casts, but detekt has no rule for
// every one, so this matches them as text: `as` followed by a type, outside
// imports and comment lines. It can be fooled by `as` inside a string, but
// not by `as?`. tool/check_native_lints.sh proves it reports.
val checkUncheckedCasts by tasks.registering {
    description = "Fails on an unchecked `as` cast in the app's Kotlin."
    group = "verification"
    val sources =
        fileTree("src/main/kotlin") {
            include("**/*.kt")
            // Pigeon's generated code (see pigeons/ble_api.dart).
            exclude("**/*.pigeon.kt")
        }
    inputs.files(sources)
    doLast {
        val cast = Regex("""(^|[^A-Za-z0-9_])as\s+[A-Za-z(]""")
        val skipped = Regex("""^\s*(import |//|\*|/\*)""")
        val findings =
            sources.files.sorted().flatMap { file ->
                file.readLines().mapIndexedNotNull { index, line ->
                    if (cast.containsMatchIn(line) && !skipped.containsMatchIn(line)) {
                        "${file.path}:${index + 1}: no_unchecked_cast: " +
                            "use `as?` and handle null: ${line.trim()}"
                    } else {
                        null
                    }
                }
            }
        if (findings.isNotEmpty()) {
            findings.forEach { logger.error(it) }
            throw GradleException("Found ${findings.size} unchecked `as` cast(s).")
        }
    }
}

// Runs detekt and the cast check in every Android build (Android Studio's
// Run, `flutter run` and `flutter build apk`), so findings fail the build
// there as SwiftLint does in Xcode. They appear in the Build window with
// links to each line.
tasks.configureEach {
    val variant =
        Regex("assemble(Debug|Profile|Release)").matchEntire(name)?.groupValues?.getOrNull(1)
    if (variant != null) {
        dependsOn("detekt$variant", checkUncheckedCasts)
    }
}
