import groovy.json.JsonSlurper
import java.nio.charset.StandardCharsets
import java.util.Base64

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Auto-inject SUPABASE_URL / SUPABASE_ANON_KEY from root `supabase.json` for local Android
// builds/runs when `--dart-define` / `--dart-define-from-file` was omitted (e.g. plain CLI or IDE).
run {
    val supabaseFile = rootProject.file("../supabase.json")
    if (supabaseFile.isFile) {
        val rawDefines = project.findProperty("dart-defines")?.toString().orEmpty()
        val encodedDefines = rawDefines
            .split(",")
            .map { it.trim() }
            .filter { it.isNotEmpty() }
            .toMutableList()

        val decodedKeys = encodedDefines.mapNotNull { encoded ->
            try {
                String(Base64.getDecoder().decode(encoded), StandardCharsets.UTF_8)
                    .substringBefore("=")
            } catch (_: IllegalArgumentException) {
                null
            }
        }.toSet()

        @Suppress("UNCHECKED_CAST")
        val parsed = JsonSlurper().parse(supabaseFile) as? Map<String, Any?>
        if (parsed != null) {
            val encoder = Base64.getEncoder()
            var changed = false
            for (key in listOf("SUPABASE_URL", "SUPABASE_ANON_KEY")) {
                if (key !in decodedKeys) {
                    val value = (parsed[key] as? String)?.trim().orEmpty()
                    if (value.isNotEmpty()) {
                        val define = "$key=$value".toByteArray(StandardCharsets.UTF_8)
                        encodedDefines.add(encoder.encodeToString(define))
                        changed = true
                    }
                }
            }
            if (changed) {
                project.extensions.extraProperties["dart-defines"] =
                    encodedDefines.joinToString(",")
            }
        }
    }
}

android {
    namespace = "com.example.zetzy"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.zetzy"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
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
