package expo.modules.iszoomed

import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition
import android.os.Build

class ExpoIsZoomedModule : Module() {
  override fun definition() = ModuleDefinition {
    Name("ExpoIsZoomed")

    Function("isZoomedDisplay") {
      false
    }

    Function("getDeviceModel") {
      val manufacturer = Build.MANUFACTURER
        .trim()
        .replaceFirstChar { it.uppercase() }
      val model = Build.MODEL.trim()
      when {
        model.isEmpty() -> manufacturer.ifEmpty { "Unknown" }
        manufacturer.isEmpty() -> model
        model.lowercase().startsWith(manufacturer.lowercase()) -> model
        else -> "$manufacturer $model"
      }
    }
  }
}
