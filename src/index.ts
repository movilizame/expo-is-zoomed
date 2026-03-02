import { NativeModulesProxy, Subscription } from 'expo-modules-core';

// Import the native module. On web, it will be resolved to ExpoIsZoomed.web.ts
// and on native platforms to ExpoIsZoomed.ts
import ExpoIsZoomedModule from './ExpoIsZoomedModule';
import { ChangeEventPayload, ExpoIsZoomedViewProps } from './ExpoIsZoomed.types';

// Get the native constant value.
export const PI = ExpoIsZoomedModule.PI;

export function isZoomedDisplay(): boolean {
  return ExpoIsZoomedModule.isZoomedDisplay();
}

export async function isZoomedDisplayAsync() {
  return await ExpoIsZoomedModule.isZoomedDisplayAsync();
}

export function getDeviceModel(): string {
  return ExpoIsZoomedModule.getDeviceModel();
}

export async function getCpuUsage() {
  return await ExpoIsZoomedModule.getCpuUsage();
}

export async function getMemoryUsage() {
  return await ExpoIsZoomedModule.getMemoryUsage();
}

/**
 * Elimina un directorio recursivamente sin bloquear el hilo JS.
 * 
 * Esta función ejecuta la eliminación en un background thread (iOS) o coroutine IO (Android),
 * lo que la hace ideal para eliminar directorios grandes con muchos archivos (~500,000 archivos)
 * sin congelar la UI.
 * 
 * @param path - Ruta absoluta del directorio a eliminar dentro del sandbox de la app
 * @returns Promise que se resuelve cuando la eliminación completa, o rechaza con un error
 * 
 * @example
 * ```typescript
 * import { deleteDirectory } from 'expo-is-zoomed';
 * 
 * try {
 *   await deleteDirectory('/path/to/cache/directory');
 *   console.log('Directorio eliminado exitosamente');
 * } catch (error) {
 *   console.error('Error al eliminar directorio:', error);
 * }
 * ```
 * 
 * @remarks
 * - La función es idempotente: si el directorio no existe, se resuelve sin error
 * - Solo acepta paths dentro del sandbox de la aplicación (validación de seguridad)
 * - El tiempo de ejecución se registra en los logs nativos para debugging
 * - En Android, considera las limitaciones de Scoped Storage en Android 10+
 */
export async function deleteDirectory(path: string): Promise<void> {
  return await ExpoIsZoomedModule.deleteDirectory(path);
}

export { ExpoIsZoomedViewProps, ChangeEventPayload };
