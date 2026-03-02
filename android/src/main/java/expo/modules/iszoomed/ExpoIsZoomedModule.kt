package expo.modules.iszoomed


import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition
import expo.modules.kotlin.Promise
import android.app.ActivityManager
import android.content.Context
import android.os.Build
import android.os.Process
import java.io.File
import kotlinx.coroutines.*

class ExpoIsZoomedModule : Module() {
  override fun definition() = ModuleDefinition {
    Name("ExpoIsZoomed")

    Constants(
      "PI" to Math.PI
    )

    Events("onChange")

    Function("isZoomedDisplay") {
      false
    }

    Function("getDeviceModel") {
      val manufacturer = Build.MANUFACTURER.replaceFirstChar { it.uppercase() }
      val model = Build.MODEL
      val deviceModel = if (model.startsWith(manufacturer)) model else "$manufacturer $model"
      deviceModel
    }

    AsyncFunction("setValueAsync") { value: String ->
      sendEvent("onChange", mapOf(
        "value" to value
      ))
    }

     // 🔥 NUEVA FUNCIÓN: Obtener memoria usada por la app
     AsyncFunction("getMemoryUsage") {
      val activityManager = appContext.reactContext?.getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager
        ?: throw Exception("No se pudo obtener la información de memoria")
    
      val runtime = Runtime.getRuntime()
      val usedMemoryMB = (runtime.totalMemory() - runtime.freeMemory()) / (1024 * 1024) // Convertir a MB
      val memoryInfo = ActivityManager.MemoryInfo()
      activityManager.getMemoryInfo(memoryInfo)
    
      mapOf(
        "usedMemoryMB" to usedMemoryMB,
        "availableMemoryMB" to (memoryInfo.availMem / (1024 * 1024)),
        "totalMemoryMB" to (memoryInfo.totalMem / (1024 * 1024))
      )
    }

    AsyncFunction("getCpuUsage") {
      getCpuUsage()
    }

    // 🔥 NUEVA FUNCIÓN: Eliminar directorio recursivamente en background thread
    AsyncFunction("deleteDirectory") { path: String ->
      // Validar que el path esté dentro del sandbox de la app
      if (!isPathInSandbox(path)) {
        throw Exception("El path está fuera del sandbox de la aplicación")
      }

      // Ejecutar en coroutine con Dispatchers.IO para no bloquear el JS thread
      // Usamos runBlocking con Dispatchers.IO para compatibilidad con Kotlin 1.9
      // El bloque se ejecuta en el dispatcher IO, y runBlocking espera su finalización
      runBlocking(Dispatchers.IO) {
        val startTime = System.currentTimeMillis()
        
        try {
          val file = File(path)
          
          // Si no existe, resolver sin error (idempotente)
          if (!file.exists()) {
            val elapsedTime = (System.currentTimeMillis() - startTime) / 1000.0
            android.util.Log.d("ExpoIsZoomed", "deleteDirectory: Path no existe, resuelto sin error (tiempo: ${String.format("%.3f", elapsedTime)}s)")
            return@runBlocking
          }

          // Eliminar recursivamente
          val deleted = file.deleteRecursively()
          
          if (deleted) {
            val elapsedTime = (System.currentTimeMillis() - startTime) / 1000.0
            android.util.Log.d("ExpoIsZoomed", "deleteDirectory: Directorio eliminado exitosamente (tiempo: ${String.format("%.3f", elapsedTime)}s, path: $path)")
          } else {
            throw Exception("No se pudo eliminar el directorio (deleteRecursively retornó false)")
          }
        } catch (e: Exception) {
          val elapsedTime = (System.currentTimeMillis() - startTime) / 1000.0
          android.util.Log.e("ExpoIsZoomed", "deleteDirectory: Error al eliminar directorio (tiempo: ${String.format("%.3f", elapsedTime)}s, error: ${e.message})")
          throw Exception("Error al eliminar directorio: ${e.message}")
        }
      }
    }
  }
  private fun getCpuUsage(): Double {
    val pid = Process.myPid()
    val activityManager = appContext.reactContext?.getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager
    val processInfo = activityManager?.runningAppProcesses?.firstOrNull { it.pid == pid }

    if (processInfo != null) {
      return processInfo.importance / 100.0  // No es exacto, pero indica nivel de uso
    }
    
    return -1.0
  }

  // Función auxiliar para validar que el path esté dentro del sandbox de la app
  private fun isPathInSandbox(path: String): Boolean {
    val context = appContext.reactContext ?: return false
    
    // Obtener los directorios del sandbox de la app
    val filesDir = context.filesDir.absolutePath
    val cacheDir = context.cacheDir.absolutePath
    val externalFilesDir = context.getExternalFilesDir(null)?.absolutePath
    val externalCacheDir = context.externalCacheDir?.absolutePath
    
    // Normalizar el path proporcionado
    val normalizedPath = File(path).canonicalPath
    
    // Verificar que el path esté dentro de alguno de los directorios del sandbox
    return normalizedPath.startsWith(filesDir) ||
           normalizedPath.startsWith(cacheDir) ||
           (externalFilesDir != null && normalizedPath.startsWith(externalFilesDir)) ||
           (externalCacheDir != null && normalizedPath.startsWith(externalCacheDir))
  }
}
