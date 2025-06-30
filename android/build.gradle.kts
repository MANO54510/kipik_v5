buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.2")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
    
    // Supprimer les warnings Java 8
    tasks.withType<JavaCompile> {
        options.compilerArgs.addAll(listOf(
            "-Xlint:-options",
            "-Xlint:-deprecation"
        ))
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}