plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services") // ✅ Firebase plugin
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.company.oneidpro" // 🔁 Make sure this matches your Firebase package name
    compileSdk = flutter.compileSdkVersion
    //ndkVersion = flutter.ndkVersion
    ndkVersion = "27.0.12077973"  // <-- set the highest NDK version here

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId = "com.company.oneidpro" // 🔁 Must match what's in google-services.json
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug") // Use real signing config for production
        }
    }
}

flutter {
    source = "../.."
}


