plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

val flutterVersionCode = project.properties["flutter.versionCode"]?.toString() ?: "1"
val flutterVersionName = project.properties["flutter.versionName"]?.toString() ?: "1.0"

android {
    namespace = "com.example.accident_prone_app"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.example.accident_prone_app"
        minSdk = 21
        targetSdk = 35
        versionCode = flutterVersionCode.toInt()
        versionName = flutterVersionName
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    lint {
        checkReleaseBuilds = false
        abortOnError = false
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = rootProject.projectDir.parentFile
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
