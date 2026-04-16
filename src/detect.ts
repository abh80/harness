export type Flavor = 'ps1' | 'sh' | 'both';

export function defaultFlavorFor(platform: NodeJS.Platform | string): 'ps1' | 'sh' | null {
  if (platform === 'win32') return 'ps1';
  if (platform === 'linux' || platform === 'darwin') return 'sh';
  return null;
}
