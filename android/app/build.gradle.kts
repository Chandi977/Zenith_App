import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// Load .env file
val dotenv = Properties()
val envFile = rootProject.file("../.env")
if (envFile.exists()) {
    dotenv.load(FileInputStream(envFile))
} else {
    println(".env file not found at: ${envFile.path}")
}

android {
    namespace = "com.example.ambulance_tracker"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.ambulance_tracker"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        manifestPlaceholders["GOOGLE_MAPS_API_KEY"] = dotenv.getProperty("GOOGLE_MAPS_API_KEY") ?: ""
        manifestPlaceholders["applicationName"] = "com.example.ambulance_tracker.MyApplication"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}


