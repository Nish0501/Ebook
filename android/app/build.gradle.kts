plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("com.google.gms.google-services")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.ebook" // 🔁 Change to a unique reverse-domain ID
    compileSdk = 35
    ndkVersion = "27.0.12077973"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.ebook" // 🔁 Updated from com.example.ebook
        minSdk = 23
        targetSdk = 35
        versionCode = 1

        versionName = "1.0.0"
    }

    // 🔐 Release signing config
    signingConfigs {
        create("release") {
            storeFile = file("keystore.jks") // 📁 This file must exist in android/ folder
            storePassword = "mypass123" // 🔁 Fill with your actual password
            keyAlias = "ebookkey"
            keyPassword = "mypass123"
        }
    }


}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:33.11.0"))
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
    implementation("com.google.firebase:firebase-storage")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    implementation("org.jetbrains.kotlin:kotlin-stdlib:2.1.20")
}

flutter {
    source = "../.."
}
