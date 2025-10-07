plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")

    // ✅ google-services ต้องอยู่ล่างสุดเสมอ
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.badminton_booking_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.badminton_booking_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // ✅ บังคับให้ใช้ multiDex ถ้า dependencies เยอะ
        multiDexEnabled = true
        
    }

    buildTypes {
        release {
            // ถ้ามี keystore จริง ให้เปลี่ยนตรงนี้
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")

    // ✅ Firebase BOM (จะจัดการ version ให้อัตโนมัติ)
    implementation(platform("com.google.firebase:firebase-bom:33.1.2"))

    // ✅ Firebase Messaging สำหรับ Push Notifications
    implementation("com.google.firebase:firebase-messaging")

    // ✅ multiDex (จำเป็นถ้า method count เกิน 64K)
    implementation("androidx.multidex:multidex:2.0.1")
}
