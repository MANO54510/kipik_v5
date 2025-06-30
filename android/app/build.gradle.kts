plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.kipik_v5"
    
    compileSdk = 35
    ndkVersion = "27.0.12077973"
    
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    
    kotlinOptions {
        jvmTarget = "17"
    }
    
    defaultConfig {
        applicationId = "com.example.kipik_v5"
        
        minSdk = 23
        targetSdk = 35
        
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Support pour MultiDex
        multiDexEnabled = true
    }
    
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
    
    // Configuration packaging pour éviter les conflits
    packaging {
        resources {
            excludes += listOf(
                "/META-INF/{AL2.0,LGPL2.1}",
                "/META-INF/DEPENDENCIES",
                "/META-INF/LICENSE",
                "/META-INF/LICENSE.txt",
                "/META-INF/NOTICE",
                "/META-INF/NOTICE.txt",
                "/META-INF/ASL2.0",
                "/META-INF/*.kotlin_module"
            )
        }
    }
    
    // Configuration lint
    lint {
        checkReleaseBuilds = false
        abortOnError = false
    }
}

flutter {
    source = "../.."
}

dependencies {
    // ❌ ERREUR CORRIGÉE : "multidx" -> "multidex"
    implementation("androidx.multidex:multidex:2.0.1")
    
    // Firebase BOM pour gérer les versions automatiquement
    implementation(platform("com.google.firebase:firebase-bom:33.7.0"))
    implementation("com.google.firebase:firebase-analytics-ktx")
    implementation("com.google.firebase:firebase-auth-ktx")
    implementation("com.google.firebase:firebase-firestore-ktx")
    
    // ❌ SUPPRIMÉ : firebase-core est déprécié et inclus automatiquement
    // implementation("com.google.firebase:firebase-core")
    
    // Dépendances supplémentaires
    implementation("androidx.work:work-runtime-ktx:2.9.0")
    implementation("androidx.annotation:annotation:1.7.1")
}