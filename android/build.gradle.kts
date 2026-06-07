allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    // AGP 8.9+ requires an explicit namespace on every Android library module.
    // Older pub packages only declare `package` in AndroidManifest.xml.
    // Register the afterEvaluate callback here — before evaluationDependsOn
    // triggers evaluation — so it fires after each subproject is configured.
    afterEvaluate {
        extensions.findByType<com.android.build.gradle.LibraryExtension>()?.apply {
            if (namespace == null) {
                val manifest = projectDir.resolve("src/main/AndroidManifest.xml")
                if (manifest.exists()) {
                    val pkg = Regex("""package\s*=\s*"([^"]+)"""")
                        .find(manifest.readText())?.groupValues?.get(1)
                    if (!pkg.isNullOrBlank()) namespace = pkg
                }
            }
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
