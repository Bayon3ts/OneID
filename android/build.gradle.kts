buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.4.0") // Android Gradle Plugin
        classpath("com.google.gms:google-services:4.4.1") // Firebase Google Services plugin
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    val newSubprojectBuildDir = newBuildDir.dir(project.name)
    project.layout.buildDirectory.set(newSubprojectBuildDir)
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
