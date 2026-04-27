allprojects {
    repositories {
        google()
        mavenCentral()
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
    project.evaluationDependsOn(":app")
}

subprojects {
    val fixNamespace = Action<Project> {
        val android = extensions.findByName("android")
        if (android is com.android.build.gradle.BaseExtension) {
            if (android.namespace == null) {
                val manifestFile = file("src/main/AndroidManifest.xml")
                if (manifestFile.exists()) {
                    try {
                        val xml = manifestFile.readText()
                        val packageMatch = Regex("""package="([^"]+)"""").find(xml)
                        val packageName = packageMatch?.groupValues?.get(1)
                        if (packageName != null) {
                            android.namespace = packageName
                        } else {
                            android.namespace = "com.example.${name.replace("-", "_")}"
                        }
                    } catch (e: Exception) {
                        android.namespace = "com.example.${name.replace("-", "_")}"
                    }
                } else {
                    android.namespace = "com.example.${name.replace("-", "_")}"
                }
            }
        }
    }
    if (state.executed) {
        fixNamespace.execute(this)
    } else {
        afterEvaluate { fixNamespace.execute(this) }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
