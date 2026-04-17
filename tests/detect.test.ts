import { describe, it, expect } from 'vitest';
import { defaultFlavorFor } from '../src/detect';

describe('defaultFlavorFor', () => {
  it('returns ps1 on win32', () => expect(defaultFlavorFor('win32')).toBe('ps1'));
  it('returns sh on linux', () => expect(defaultFlavorFor('linux')).toBe('sh'));
  it('returns sh on darwin', () => expect(defaultFlavorFor('darwin')).toBe('sh'));
  it('returns null on unknown', () => expect(defaultFlavorFor('aix')).toBeNull());
});
