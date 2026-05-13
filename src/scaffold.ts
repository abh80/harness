import { cp, mkdir, rm, stat } from 'node:fs/promises';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

export type Flavor = 'ps1' | 'sh' | 'both';
export type Sample = 'cpp' | 'java' | 'scala' | 'python' | 'node';

export interface ScaffoldOpts {
  target: string;
  flavor: Flavor;
  samples: Sample[];
  templatesRoot?: string;
}

export async function scaffold(opts: ScaffoldOpts): Promise<void> {
  const root = opts.templatesRoot ?? defaultTemplatesRoot();
  await mkdir(opts.target, { recursive: true });

  const flavors: ('ps1' | 'sh')[] =
    opts.flavor === 'both' ? ['ps1', 'sh'] : [opts.flavor];
  for (const f of flavors) {
    await cp(join(root, f, 'scripts'), join(opts.target, 'scripts'), { recursive: true });
  }

  for (const s of opts.samples) {
    await cp(join(root, 'samples', s), join(opts.target, 'samples', `${s}-hello`), { recursive: true });
  }

  await cp(join(root, 'shared', 'README.md.tpl'), join(opts.target, 'README.md'));
  await cp(join(root, 'shared', 'CLAUDE.md.tpl'), join(opts.target, 'CLAUDE.md'));
  await cp(join(root, 'shared', 'gitignore.tpl'), join(opts.target, '.gitignore'));

  if (opts.flavor === 'both') {
    await mkdir(join(opts.target, '.github', 'workflows'), { recursive: true });
    await cp(join(root, 'shared', 'ci.yml.tpl'), join(opts.target, '.github', 'workflows', 'test.yml'));
  }
}

function defaultTemplatesRoot(): string {
  const here = dirname(fileURLToPath(import.meta.url));
  return join(here, '..', 'templates');
}

export interface InstallOpts {
  target: string;
  flavor?: Flavor;
  scriptsDir?: string;
  templatesRoot?: string;
}

export interface InstallResult {
  flavor: Flavor;
  scriptsDir: string;
}

export async function installScripts(opts: InstallOpts): Promise<InstallResult> {
  const root = opts.templatesRoot ?? defaultTemplatesRoot();
  const detected = await detectExisting(opts.target);
  const scriptsDir = opts.scriptsDir ?? detected?.scriptsDir ?? '.harness/scripts';
  const flavor = opts.flavor ?? detected?.flavor;
  if (!flavor) throw new Error(`Cannot detect shell flavor in ${opts.target}; pass --shell`);
  const flavors: ('ps1' | 'sh')[] = flavor === 'both' ? ['ps1', 'sh'] : [flavor];
  const dest = join(opts.target, scriptsDir);
  await rm(dest, { recursive: true, force: true });
  await mkdir(dirname(dest), { recursive: true });
  for (const f of flavors) {
    await cp(join(root, f, 'scripts'), dest, { recursive: true });
  }
  return { flavor, scriptsDir };
}

async function detectExisting(target: string): Promise<{ flavor: Flavor; scriptsDir: string } | null> {
  for (const dir of ['.harness/scripts', 'scripts']) {
    const flavor = await detectFlavorIn(join(target, dir));
    if (flavor) return { flavor, scriptsDir: dir };
  }
  return null;
}

async function detectFlavorIn(scripts: string): Promise<Flavor | null> {
  const hasPs1 = await exists(join(scripts, 'build.ps1'));
  const hasSh = await exists(join(scripts, 'build.sh'));
  if (hasPs1 && hasSh) return 'both';
  if (hasPs1) return 'ps1';
  if (hasSh) return 'sh';
  return null;
}

async function exists(p: string): Promise<boolean> {
  try { await stat(p); return true; } catch { return false; }
}
