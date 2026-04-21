#!/usr/bin/env node
import { Command } from 'commander';
import { resolve } from 'node:path';
import { runWizard, type WizardResult } from './wizard.js';
import { scaffold, type Sample } from './scaffold.js';
import { gitInit } from './git.js';
import type { Flavor } from './detect.js';

const program = new Command();
program
  .name('create-snap-harness')
  .argument('[project]', 'project directory name')
  .option('--shell <flavor>', 'ps1 | sh | both')
  .option('--samples <list>', 'comma-separated: cpp,java,scala,python,node,none')
  .option('--no-git', 'skip git init')
  .option('--no-commit', 'skip initial commit')
  .action(async (project: string | undefined, opts) => {
    const defaults: Partial<WizardResult> = {};
    if (project) defaults.projectName = project;
    if (opts.shell) defaults.flavor = opts.shell as Flavor;
    if (opts.samples) {
      defaults.samples = opts.samples === 'none' ? [] :
        (opts.samples.split(',') as Sample[]);
    }
    if (opts.git === false) { defaults.gitInit = false; defaults.initialCommit = false; }
    if (opts.commit === false) defaults.initialCommit = false;

    const result = await runWizard(defaults);
    const target = resolve(process.cwd(), result.projectName);
    await scaffold({ target, flavor: result.flavor, samples: result.samples });
    if (result.gitInit) await gitInit(target, result.initialCommit);

    printPostScaffold(target, result.flavor);
  });

program.parseAsync();

function printPostScaffold(target: string, flavor: Flavor): void {
  console.log(`\nScaffolded at ${target}\n`);
  if (flavor === 'ps1' || flavor === 'both') {
    console.log('PowerShell:');
    console.log('  cd ' + target);
    console.log('  .\\scripts\\install.ps1 -All');
    console.log('  .\\scripts\\build.ps1 -All');
    console.log('  .\\scripts\\record.ps1 -All');
    console.log('  .\\scripts\\test.ps1 -All\n');
  }
  if (flavor === 'sh' || flavor === 'both') {
    console.log('Bash:');
    console.log('  cd ' + target);
    console.log('  ./scripts/install.sh --all');
    console.log('  ./scripts/build.sh --all');
    console.log('  ./scripts/record.sh --all');
    console.log('  ./scripts/test.sh --all');
  }
}
