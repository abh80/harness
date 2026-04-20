import { input, confirm, select, checkbox } from '@inquirer/prompts';
import { defaultFlavorFor, type Flavor } from './detect.js';
import type { Sample } from './scaffold.js';

export interface WizardResult {
  projectName: string;
  flavor: Flavor;
  samples: Sample[];
  gitInit: boolean;
  initialCommit: boolean;
}

export async function runWizard(defaults: Partial<WizardResult>): Promise<WizardResult> {
  const projectName = defaults.projectName ?? await input({ message: 'Project name:' });

  let flavor = defaults.flavor;
  if (!flavor) {
    const platDefault = defaultFlavorFor(process.platform);
    if (platDefault === 'ps1') {
      const ok = await confirm({ message: 'Windows detected — install PowerShell scripts (.ps1)?', default: true });
      flavor = ok ? 'ps1' : await pickFlavor();
    } else if (platDefault === 'sh') {
      const ok = await confirm({ message: 'Unix detected — install Bash scripts (.sh)?', default: true });
      flavor = ok ? 'sh' : await pickFlavor();
    } else {
      flavor = await pickFlavor();
    }
  }

  const samples = defaults.samples ?? await checkbox<Sample>({
    message: 'Sample templates:',
    choices: [
      { value: 'cpp' }, { value: 'java' }, { value: 'scala' },
      { value: 'python' }, { value: 'node' },
    ],
  });

  const gitInit = defaults.gitInit ?? await confirm({ message: 'git init?', default: true });
  const initialCommit = gitInit && (defaults.initialCommit ?? await confirm({ message: 'Create initial commit?', default: true }));

  return { projectName, flavor, samples, gitInit, initialCommit };
}

async function pickFlavor(): Promise<Flavor> {
  return select<Flavor>({
    message: 'Pick shell flavor:',
    choices: [{ value: 'ps1' }, { value: 'sh' }, { value: 'both' }],
  });
}
