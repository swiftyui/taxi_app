import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val defaultReleaseSigningFile = rootProject.file("key.properties")
val releaseSigningFile = providers.environmentVariable("HAMBA_ANDROID_KEY_PROPERTIES")
    .map { rootProject.file(it) }
    .getOrElse(defaultReleaseSigningFile)
val releaseSigningProperties = Properties().apply {
    if (releaseSigningFile.isFile) {
        releaseSigningFile.inputStream().use { load(it) }
    }
}
val releaseKeystore = releaseSigningProperties.getProperty("storeFile")
    ?.takeIf { it.isNotBlank() }
    ?.let {
        if (releaseSigningFile == defaultReleaseSigningFile) file(it)
        else releaseSigningFile.parentFile.resolve(it)
    }
val missingSigningProperties = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
    .filter { releaseSigningProperties.getProperty(it).isNullOrBlank() }
val releaseSigningError = when {
    !releaseSigningFile.isFile ->
        "Android release signing requires android/key.properties or HAMBA_ANDROID_KEY_PROPERTIES with the HambaGo upload keystore settings."
    missingSigningProperties.isNotEmpty() ->
        "Android release signing is missing these properties: ${missingSigningProperties.joinToString()}."
    releaseKeystore?.isFile != true ->
        "Android release signing could not find the keystore configured as storeFile."
    else -> null
}

val validateReleaseUploadKey = tasks.register("validateReleaseUploadKey") {
    doLast {
        if (releaseSigningError != null) throw GradleException(releaseSigningError)
    }
}

tasks.matching { it.name == "preReleaseBuild" || it.name == "signReleaseBundle" }.configureEach {
    dependsOn(validateReleaseUploadKey)
}

android {
    namespace = "com.vanzylarno.taxiApp"
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    val releaseSigningConfig = if (releaseSigningError == null) {
        signingConfigs.create("release") {
            keyAlias = releaseSigningProperties.getProperty("keyAlias")
            keyPassword = releaseSigningProperties.getProperty("keyPassword")
            storeFile = releaseKeystore
            storePassword = releaseSigningProperties.getProperty("storePassword")
        }
    } else {
        null
    }

    defaultConfig {
        applicationId = "com.vanzylarno.taxiApp"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = releaseSigningConfig

            // Fixed property names for modern Kotlin DSL
            isMinifyEnabled = true
            isShrinkResources = true
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
