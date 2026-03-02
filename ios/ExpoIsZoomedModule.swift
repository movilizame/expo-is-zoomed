import ExpoModulesCore
import UIKit
import React
private func mapToDevice(identifier: String) -> String {
    switch identifier {
    // iPhone
    case "iPhone1,1": return "iPhone 1G"
    case "iPhone1,2": return "iPhone 3G"
    case "iPhone2,1": return "iPhone 3GS"
    case "iPhone3,1", "iPhone3,2", "iPhone3,3": return "iPhone 4"
    case "iPhone4,1": return "iPhone 4S"
    case "iPhone5,1", "iPhone5,2": return "iPhone 5"
    case "iPhone5,3", "iPhone5,4": return "iPhone 5c"
    case "iPhone6,1", "iPhone6,2": return "iPhone 5s"
    case "iPhone7,2": return "iPhone 6"
    case "iPhone7,1": return "iPhone 6 Plus"
    case "iPhone8,1": return "iPhone 6s"
    case "iPhone8,2": return "iPhone 6s Plus"
    case "iPhone8,4": return "iPhone SE (1st generation)"
    case "iPhone9,1", "iPhone9,3": return "iPhone 7"
    case "iPhone9,2", "iPhone9,4": return "iPhone 7 Plus"
    case "iPhone10,1", "iPhone10,4": return "iPhone 8"
    case "iPhone10,2", "iPhone10,5": return "iPhone 8 Plus"
    case "iPhone10,3", "iPhone10,6": return "iPhone X"
    case "iPhone11,2": return "iPhone XS"
    case "iPhone11,4", "iPhone11,6": return "iPhone XS Max"
    case "iPhone11,8": return "iPhone XR"
    case "iPhone12,1": return "iPhone 11"
    case "iPhone12,3": return "iPhone 11 Pro"
    case "iPhone12,5": return "iPhone 11 Pro Max"
    case "iPhone12,8": return "iPhone SE (2nd generation)"
    case "iPhone13,1": return "iPhone 12 mini"
    case "iPhone13,2": return "iPhone 12"
    case "iPhone13,3": return "iPhone 12 Pro"
    case "iPhone13,4": return "iPhone 12 Pro Max"
    case "iPhone14,4": return "iPhone 13 mini"
    case "iPhone14,5": return "iPhone 13"
    case "iPhone14,2": return "iPhone 13 Pro"
    case "iPhone14,3": return "iPhone 13 Pro Max"
    case "iPhone14,6": return "iPhone SE (3rd generation)"
    case "iPhone15,2": return "iPhone 14"
    case "iPhone15,3": return "iPhone 14 Plus"
    case "iPhone15,2": return "iPhone 14 Pro"
    case "iPhone15,3": return "iPhone 14 Pro Max"
    case "iPhone16,1": return "iPhone 15"
    case "iPhone16,2": return "iPhone 15 Plus"
    case "iPhone16,3": return "iPhone 15 Pro"
    case "iPhone16,4": return "iPhone 15 Pro Max"
    
    // Otros dispositivos
    default: return identifier
    }
}
public class ExpoIsZoomedModule: Module {
  // Each module class must implement the definition function. The definition consists of components
  // that describes the module's functionality and behavior.
  // See https://docs.expo.dev/modules/module-api for more details about available components.
  public func definition() -> ModuleDefinition {
    // Sets the name of the module that JavaScript code will use to refer to the module. Takes a string as an argument.
    // Can be inferred from module's class name, but it's recommended to set it explicitly for clarity.
    // The module will be accessible from `requireNativeModule('ExpoIsZoomed')` in JavaScript.
    Name("ExpoIsZoomed")

    // Sets constant properties on the module. Can take a dictionary or a closure that returns a dictionary.
    Constants([
      "PI": Double.pi
    ])

    // Defines event names that the module can send to JavaScript.
    Events("onChange")

    // Defines a JavaScript synchronous function that runs the native code on the JavaScript thread.
    Function("isZoomedDisplay") { 
        let isZoomed = UIScreen.main.nativeScale > UIScreen.main.scale
        print(UIScreen.main.nativeScale);
        print(UIScreen.main.scale);
        return isZoomed
    }

    Function ("getDeviceModel") {
      var systemInfo = utsname()
      uname(&systemInfo)
      let machineMirror = Mirror(reflecting: systemInfo.machine)
      let identifier = machineMirror.children.reduce("") { identifier, element in
        guard let value = element.value as? Int8, value != 0 else { return identifier }
        return identifier + String(UnicodeScalar(UInt8(value)))
      }

      let modelName = mapToDevice(identifier: identifier)
      return modelName
    }

    // Defines a JavaScript function that always returns a Promise and whose native code
    // is by default dispatched on the different thread than the JavaScript runtime runs on.
    AsyncFunction("isZoomedDisplayAsync") { () in
    
    }


    // 🔥 NUEVA FUNCIÓN: Obtener memoria usada por la app
    AsyncFunction("getMemoryUsage") { () -> [String: Double] in
      let usedMemoryMB = getUsedMemory() / (1024 * 1024) // Convertir a MB
      let totalMemoryMB = Double(ProcessInfo.processInfo.physicalMemory) / (1024 * 1024) // Memoria total del sistema en MB

      return [
        "usedMemoryMB": usedMemoryMB,
        "totalMemoryMB": totalMemoryMB
      ]
    }

    AsyncFunction("getCpuUsage") { () -> Double in
      let usage = self.getCpuUsage()
      if usage < 0 {
        throw NSError(domain: "ExpoIsZoomed", code: 500, userInfo: [NSLocalizedDescriptionKey: "No se pudo obtener el uso de CPU"])
      }
      return usage
    }

    // 🔥 NUEVA FUNCIÓN: Eliminar directorio recursivamente en background thread
    AsyncFunction("deleteDirectory") { (path: String) -> Void in
      return try await withCheckedThrowingContinuation { continuation in
        // Validar que el path esté dentro del sandbox de la app
        guard self.isPathInSandbox(path) else {
          continuation.resume(throwing: NSError(
            domain: "ExpoIsZoomed",
            code: 403,
            userInfo: [NSLocalizedDescriptionKey: "El path está fuera del sandbox de la aplicación"]
          ))
          return
        }

        // Ejecutar en background thread para no bloquear el JS thread
        DispatchQueue.global(qos: .background).async {
          let startTime = Date()
          let fileManager = FileManager.default
          let url = URL(fileURLWithPath: path)

          // Verificar si el path existe
          var isDirectory: ObjCBool = false
          let exists = fileManager.fileExists(atPath: path, isDirectory: &isDirectory)

          // Si no existe, resolver sin error (idempotente)
          if !exists {
            let elapsedTime = Date().timeIntervalSince(startTime)
            print("[ExpoIsZoomed] deleteDirectory: Path no existe, resuelto sin error (tiempo: \(String(format: "%.3f", elapsedTime))s)")
            continuation.resume()
            return
          }

          // Eliminar recursivamente
          do {
            try fileManager.removeItem(at: url)
            let elapsedTime = Date().timeIntervalSince(startTime)
            print("[ExpoIsZoomed] deleteDirectory: Directorio eliminado exitosamente (tiempo: \(String(format: "%.3f", elapsedTime))s, path: \(path))")
            continuation.resume()
          } catch {
            let elapsedTime = Date().timeIntervalSince(startTime)
            print("[ExpoIsZoomed] deleteDirectory: Error al eliminar directorio (tiempo: \(String(format: "%.3f", elapsedTime))s, error: \(error.localizedDescription))")
            continuation.resume(throwing: NSError(
              domain: "ExpoIsZoomed",
              code: 500,
              userInfo: [NSLocalizedDescriptionKey: "Error al eliminar directorio: \(error.localizedDescription)"]
            ))
          }
        }
      }
    }

  }
   // Función auxiliar para obtener la memoria usada por la app
  private func getUsedMemory() -> Double {
    var taskInfo = mach_task_basic_info()
    var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

    let kerr: kern_return_t = withUnsafeMutablePointer(to: &taskInfo) {
        $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
            task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
        }
    }

    if kerr == KERN_SUCCESS {
        // Aseguramos que se devuelve un valor en tipo Double
        return Double(taskInfo.resident_size)
    } else {
        return 0.0
    }
}
  private func getCpuUsage() -> Double {
    var threadsList = thread_act_array_t(bitPattern: 0)
    var threadCount = mach_msg_type_number_t(0)
    var totalUsage: Double = 0.0

    let result = task_threads(mach_task_self_, &threadsList, &threadCount)
    if result != KERN_SUCCESS { return -1.0 }

    if let threads = threadsList {
      for i in 0..<Int(threadCount) {
        var threadInfo = thread_basic_info()
        var threadInfoCount = mach_msg_type_number_t(THREAD_INFO_MAX)

        let kr = withUnsafeMutablePointer(to: &threadInfo) {
          $0.withMemoryRebound(to: integer_t.self, capacity: Int(threadInfoCount)) {
            thread_info(threads[i], thread_flavor_t(THREAD_BASIC_INFO), $0, &threadInfoCount)
          }
        }

        if kr == KERN_SUCCESS {
          let usage = Double(threadInfo.cpu_usage) / Double(TH_USAGE_SCALE) * 100.0
          totalUsage += usage
        }
      }
    }

    return totalUsage
  }

  // Función auxiliar para validar que el path esté dentro del sandbox de la app
  private func isPathInSandbox(_ path: String) -> Bool {
    // Obtener el directorio home de la app (sandbox root)
    let homeDirectory = NSHomeDirectory()
    let homeURL = URL(fileURLWithPath: homeDirectory)
    
    // Normalizar el path proporcionado
    let pathURL = URL(fileURLWithPath: path).standardizedFileURL
    let homeURLStandardized = homeURL.standardizedFileURL
    
    // Verificar que el path esté dentro del home directory
    // Usamos hasDirectoryPath para manejar correctamente los paths que terminan en "/"
    return pathURL.path.hasPrefix(homeURLStandardized.path)
  }
}
