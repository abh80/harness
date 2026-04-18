import { cp, mkdir } from 'node:fs/promises';
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
