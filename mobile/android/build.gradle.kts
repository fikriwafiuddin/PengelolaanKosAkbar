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

// API 37 hanya tersedia sebagai platform minor-versioned (37.0/37.1/
// 37.2) sejak skema penomoran minor Android SDK — tidak ada paket
// "android-37" polos. Plugin yang menulis `compileSdk = 37` tanpa
// `compileSdkMinor` (mis. flutter_local_notifications 23.x) membuat
// AGP mencari hash "android-37" yang tidak ada dan build gagal
// ("Failed to find target with hash string 'android-37'").
// Perbaikan: lengkapi compileSdkMinor = 0 di semua modul Android
// yang memakai compileSdk 37 (butuh AGP >= 9.1.0 — refleksi dipakai
// agar tidak perlu mengimpor tipe CommonExtension yang generiknya
// berubah antar versi AGP).
//
// PENTING: blok ini harus berada SEBELUM `evaluationDependsOn(":app")`
// di bawah — hook afterEvaluate tidak bisa didaftarkan untuk proyek
// yang sudah terevaluasi.
subprojects {
    afterEvaluate {
        val androidExtension = extensions.findByName("android") ?: return@afterEvaluate
        val getCompileSdk = androidExtension.javaClass.methods.firstOrNull { it.name == "getCompileSdk" }
        val setCompileSdkMinor = androidExtension.javaClass.methods.firstOrNull { it.name == "setCompileSdkMinor" }
        if (getCompileSdk?.invoke(androidExtension) == 37 && setCompileSdkMinor != null) {
            setCompileSdkMinor.invoke(androidExtension, 0)
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
