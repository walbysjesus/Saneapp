plugins {
    id("com.google.gms.google-services") version "4.4.2" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
        maven(url = "https://storage.googleapis.com/download.flutter.io")
        maven(url = "https://phonepe.mycloudrepo.io/public/repositories/phonepe-intentsdk-android")
    }
}

configurations.all {
    resolutionStrategy {
        // Keep AndroidX on consistent versions during dependency resolution.
        force("androidx.appcompat:appcompat:1.6.1")
        force("androidx.core:core:1.12.0")
        force("com.google.android.material:material:1.11.0")
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
