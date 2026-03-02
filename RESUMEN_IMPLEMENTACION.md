# Resumen de Implementación: expo-is-zoomed

## Descripción General

`expo-is-zoomed` es un módulo nativo de Expo que proporciona utilidades para detectar pantalla con zoom y obtener información del dispositivo (isZoomedDisplay, getDeviceModel, getCpuUsage, getMemoryUsage, deleteDirectory) en aplicaciones React Native/Expo. El módulo está implementado tanto para iOS (Swift) como para Android (Kotlin).

## API Disponible

### Constantes

- **`PI`**: Constante matemática Pi (3.14159...)
  - iOS: `Double.pi`
  - Android: `Math.PI`

### Funciones Síncronas

#### 1. `isZoomedDisplay(): boolean`
Detecta si el dispositivo iOS tiene la pantalla con zoom activado.
- **iOS**: Compara `UIScreen.main.nativeScale` con `UIScreen.main.scale`
- **Android**: Retorna `false` (no implementado)
- **Retorna**: `boolean`

#### 2. `getDeviceModel(): string`
Obtiene el modelo del dispositivo en formato legible.
- **iOS**: Mapea el identificador de hardware (ej: "iPhone15,2") a nombre legible (ej: "iPhone 14 Pro")
- **Android**: Combina `Build.MANUFACTURER` y `Build.MODEL`
- **Retorna**: `string` con el nombre del dispositivo

### Funciones Asíncronas

#### 3. `isZoomedDisplayAsync(): Promise<boolean>`
Versión asíncrona de `isZoomedDisplay()`.
- **Retorna**: `Promise<boolean>`

#### 4. `getMemoryUsage(): Promise<{usedMemoryMB: number, totalMemoryMB: number}>`
Obtiene información sobre el uso de memoria de la aplicación.

**iOS:**
- `usedMemoryMB`: Memoria residente del proceso en MB
- `totalMemoryMB`: Memoria física total del sistema en MB
- Usa `mach_task_basic_info` para obtener información del proceso

**Android:**
- `usedMemoryMB`: Memoria usada por la app (totalMemory - freeMemory) en MB
- `availableMemoryMB`: Memoria disponible del sistema en MB
- `totalMemoryMB`: Memoria total del sistema en MB
- Usa `ActivityManager` y `Runtime` para obtener información

**Retorna**: `Promise<object>` con las propiedades de memoria

#### 5. `getCpuUsage(): Promise<number>`
Obtiene el porcentaje de uso de CPU de la aplicación.

**iOS:**
- Suma el uso de CPU de todos los threads del proceso
- Usa `task_threads` y `thread_info` con `THREAD_BASIC_INFO`
- Retorna porcentaje (0-100) o -1 si hay error

**Android:**
- Usa `ActivityManager.runningAppProcesses` para obtener información del proceso
- Retorna un valor aproximado basado en `importance` o -1 si hay error

**Retorna**: `Promise<number>` con el porcentaje de uso de CPU

#### 6. `deleteDirectory(path: string): Promise<void>`
Elimina un directorio recursivamente sin bloquear el hilo principal de JavaScript.

**Características:**
- Ejecuta en background thread (iOS) o coroutine IO (Android)
- Ideal para eliminar directorios grandes con muchos archivos (~500,000 archivos)
- **Idempotente**: Si el directorio no existe, se resuelve sin error
- **Validación de seguridad**: Solo acepta paths dentro del sandbox de la aplicación
- Registra tiempo de ejecución en logs nativos para debugging

**Validación de Sandbox:**

**iOS:**
- Valida que el path esté dentro de `NSHomeDirectory()`
- Normaliza paths usando `URL.standardizedFileURL`

**Android:**
- Valida que el path esté dentro de:
  - `context.filesDir`
  - `context.cacheDir`
  - `context.getExternalFilesDir(null)`
  - `context.externalCacheDir`
- Normaliza paths usando `File.canonicalPath`

**Parámetros:**
- `path`: `string` - Ruta absoluta del directorio a eliminar dentro del sandbox

**Retorna**: `Promise<void>` que se resuelve cuando la eliminación completa

**Errores:**
- Código 403: Path fuera del sandbox
- Código 500: Error al eliminar el directorio

## Ejemplo de Uso en React Native/Expo

```typescript
import {
  PI,
  isZoomedDisplay,
  isZoomedDisplayAsync,
  getDeviceModel,
  getCpuUsage,
  getMemoryUsage,
  deleteDirectory
} from 'expo-is-zoomed';

// Obtener constante
console.log('PI:', PI);

// Verificar zoom de pantalla (síncrono)
const isZoomed = isZoomedDisplay();
console.log('Pantalla con zoom:', isZoomed);

// Verificar zoom de pantalla (asíncrono)
const isZoomedAsync = await isZoomedDisplayAsync();
console.log('Pantalla con zoom (async):', isZoomedAsync);

// Obtener modelo del dispositivo
const deviceModel = getDeviceModel();
console.log('Modelo del dispositivo:', deviceModel);

// Obtener uso de memoria
try {
  const memoryInfo = await getMemoryUsage();
  console.log('Memoria usada:', memoryInfo.usedMemoryMB, 'MB');
  console.log('Memoria total:', memoryInfo.totalMemoryMB, 'MB');
  // En Android también está disponible: memoryInfo.availableMemoryMB
} catch (error) {
  console.error('Error al obtener memoria:', error);
}

// Obtener uso de CPU
try {
  const cpuUsage = await getCpuUsage();
  if (cpuUsage >= 0) {
    console.log('Uso de CPU:', cpuUsage.toFixed(2), '%');
  } else {
    console.log('No se pudo obtener el uso de CPU');
  }
} catch (error) {
  console.error('Error al obtener CPU:', error);
}

// Eliminar directorio
try {
  // Ejemplo: eliminar directorio de caché
  const cachePath = '/path/to/cache/directory'; // Debe estar dentro del sandbox
  await deleteDirectory(cachePath);
  console.log('Directorio eliminado exitosamente');
} catch (error) {
  console.error('Error al eliminar directorio:', error);
}
```

## Estructura del Módulo

### Archivos Principales

1. **`src/index.ts`**: Punto de entrada del módulo, exporta todas las funciones públicas
2. **`src/ExpoIsZoomedModule.ts`**: Carga el módulo nativo usando `requireNativeModule`
3. **`src/ExpoIsZoomed.types.ts`**: Define tipos TypeScript para props y eventos
4. **`ios/ExpoIsZoomedModule.swift`**: Implementación nativa para iOS
5. **`android/src/main/java/expo/modules/iszoomed/ExpoIsZoomedModule.kt`**: Implementación nativa para Android

### Configuración

- **Package**: `expo-is-zoomed`
- **Versión**: `0.1.0`
- **Peer Dependencies**: 
  - `expo`: `*`
  - `react`: `*`
  - `react-native`: `^0.74.3`

## Consideraciones de Implementación

### iOS

- Usa `ExpoModulesCore` para la integración con Expo
- Implementa validación de sandbox usando `NSHomeDirectory()`
- Usa `DispatchQueue.global(qos: .background)` para operaciones en background
- Implementa funciones auxiliares privadas:
  - `getUsedMemory()`: Usa `mach_task_basic_info`
  - `getCpuUsage()`: Usa `task_threads` y `thread_info`
  - `isPathInSandbox()`: Valida paths dentro del sandbox
  - `mapToDevice()`: Mapea identificadores de hardware a nombres legibles

### Android

- Usa `expo.modules.kotlin` para la integración con Expo
- Implementa validación de sandbox usando múltiples directorios del contexto
- Usa `Dispatchers.IO` con coroutines para operaciones en background
- Implementa funciones auxiliares privadas:
  - `getCpuUsage()`: Usa `ActivityManager.runningAppProcesses`
  - `isPathInSandbox()`: Valida paths dentro de los directorios del sandbox
- Considera limitaciones de Scoped Storage en Android 10+

### Seguridad

- **Validación de Sandbox**: Todas las operaciones de archivos validan que los paths estén dentro del sandbox de la aplicación
- **Normalización de Paths**: Los paths se normalizan antes de la validación para prevenir ataques de path traversal

### Performance

- **Operaciones en Background**: `deleteDirectory` se ejecuta en threads separados para no bloquear el hilo principal
- **Logging**: Se registra el tiempo de ejecución de operaciones críticas para debugging
- **Idempotencia**: `deleteDirectory` es idempotente, puede llamarse múltiples veces sin error

## Casos de Uso Comunes

1. **Gestión de Caché**: Usar `deleteDirectory` para limpiar directorios de caché grandes
2. **Monitoreo de Performance**: Usar `getMemoryUsage` y `getCpuUsage` para monitorear el rendimiento de la app
3. **Detectar Configuración del Dispositivo**: Usar `isZoomedDisplay` y `getDeviceModel` para adaptar la UI
4. **Debugging**: Usar logs nativos para diagnosticar problemas de performance

## Notas Adicionales

- El módulo está diseñado para funcionar tanto en desarrollo como en producción
- Las funciones asíncronas siempre retornan Promises
- Los errores se propagan correctamente desde el código nativo a JavaScript
- El módulo soporta tanto Expo managed como bare React Native projects
