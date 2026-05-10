import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { mkdtemp, rm, stat } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { scaffold } from '../src/scaffold';

let dir: string;
beforeEach(async () => { dir = await mkdtemp(join(tmpdir(), 'snap-')); });
afterEach(async () => { await rm(dir, { recursive: true, force: true }); });

describe('scaffold', () => {
  it('copies ps1 scripts when flavor=ps1', async () => {
    await scaffold({ target: dir, flavor: 'ps1', samples: [], templatesRoot: 'templates' });
    await stat(join(dir, 'scripts', 'install.ps1'));
    await expect(stat(join(dir, 'scripts', 'install.sh'))).rejects.toThrow();
  });

  it('copies both flavors when flavor=both', async () => {
    await scaffold({ target: dir, flavor: 'both', samples: [], templatesRoot: 'templates' });
    await stat(join(dir, 'scripts', 'install.ps1'));
    await stat(join(dir, 'scripts', 'install.sh'));
    await stat(join(dir, '.github', 'workflows', 'test.yml'));
  });

  it('copies selected samples only', async () => {
    await scaffold({ target: dir, flavor: 'ps1', samples: ['python', 'node'], templatesRoot: 'templates' });
    await stat(join(dir, 'samples', 'python-hello'));
    await stat(join(dir, 'samples', 'node-hello'));
    await expect(stat(join(dir, 'samples', 'cpp-hello'))).rejects.toThrow();
  });
});
