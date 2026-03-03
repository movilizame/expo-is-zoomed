import ExpoModulesCore
import UIKit

private func mapToDevice(identifier: String) -> String {
    switch identifier {
    // Simulator
    case "i386", "x86_64", "arm64":
        #if targetEnvironment(simulator)
        return "Simulator"
        #else
        return identifier
        #endif

    // iPhone
    case "iPhone1,1": return "iPhone"
    case "iPhone1,2": return "iPhone 3G"
    case "iPhone2,1": return "iPhone 3GS"
    case "iPhone3,1", "iPhone3,2", "iPhone3,3": return "iPhone 4"
    case "iPhone4,1": return "iPhone 4S"
    case "iPhone5,1", "iPhone5,2": return "iPhone 5"
    case "iPhone5,3", "iPhone5,4": return "iPhone 5c"
    case "iPhone6,1", "iPhone6,2": return "iPhone 5s"
    case "iPhone7,1": return "iPhone 6 Plus"
    case "iPhone7,2": return "iPhone 6"
    case "iPhone8,1": return "iPhone 6s"
    case "iPhone8,2": return "iPhone 6s Plus"
    case "iPhone8,3", "iPhone8,4": return "iPhone SE (1st generation)"
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
    case "iPhone14,2": return "iPhone 13 Pro"
    case "iPhone14,3": return "iPhone 13 Pro Max"
    case "iPhone14,4": return "iPhone 13 mini"
    case "iPhone14,5": return "iPhone 13"
    case "iPhone14,6": return "iPhone SE (3rd generation)"
    case "iPhone14,7": return "iPhone 14"
    case "iPhone14,8": return "iPhone 14 Plus"
    case "iPhone15,2": return "iPhone 14 Pro"
    case "iPhone15,3": return "iPhone 14 Pro Max"
    case "iPhone15,4": return "iPhone 15"
    case "iPhone15,5": return "iPhone 15 Plus"
    case "iPhone16,1": return "iPhone 15 Pro"
    case "iPhone16,2": return "iPhone 15 Pro Max"
    case "iPhone17,1": return "iPhone 16"
    case "iPhone17,2": return "iPhone 16 Plus"
    case "iPhone17,3": return "iPhone 16 Pro"
    case "iPhone17,4": return "iPhone 16 Pro Max"
    case "iPhone17,5": return "iPhone 16e"

    // iPad
    case "iPad2,5", "iPad2,6", "iPad2,7": return "iPad mini"
    case "iPad4,1", "iPad4,2", "iPad4,3": return "iPad Air"
    case "iPad4,4", "iPad4,5", "iPad4,6": return "iPad mini 2"
    case "iPad4,7", "iPad4,8", "iPad4,9": return "iPad mini 3"
    case "iPad5,1", "iPad5,2": return "iPad mini 4"
    case "iPad5,3", "iPad5,4": return "iPad Air 2"
    case "iPad6,3", "iPad6,4": return "iPad Pro (9.7-inch)"
    case "iPad6,7", "iPad6,8": return "iPad Pro (12.9-inch)"
    case "iPad6,11", "iPad6,12": return "iPad (5th generation)"
    case "iPad7,1", "iPad7,2": return "iPad Pro (12.9-inch, 2nd gen)"
    case "iPad7,3", "iPad7,4": return "iPad Pro (10.5-inch)"

    default: return identifier
    }
}

public class ExpoIsZoomedModule: Module {
  public func definition() -> ModuleDefinition {
    Name("ExpoIsZoomed")

    Function("isZoomedDisplay") {
      let isZoomed = UIScreen.main.nativeScale > UIScreen.main.scale
      return isZoomed
    }

    Function("getDeviceModel") {
      var systemInfo = utsname()
      uname(&systemInfo)
      let machineBytes = systemInfo.machine
      let machine = withUnsafePointer(to: machineBytes) {
        $0.withMemoryRebound(to: CChar.self, capacity: MemoryLayout.size(ofValue: machineBytes)) {
          String(cString: $0)
        }
      }
      return mapToDevice(identifier: machine)
    }
  }
}
