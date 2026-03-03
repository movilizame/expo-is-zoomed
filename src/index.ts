import ExpoIsZoomedModule from './ExpoIsZoomedModule';

export function isZoomedDisplay(): boolean {
  return ExpoIsZoomedModule.isZoomedDisplay();
}

export function getDeviceModel(): string {
  return ExpoIsZoomedModule.getDeviceModel();
}
