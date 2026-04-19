import { spawn } from 'node:child_process';

export async function gitInit(cwd: string, makeCommit: boolean): Promise<void> {
  await run('git', ['init'], cwd);
  if (makeCommit) {
    await run('git', ['add', '.'], cwd);
    await run('git', ['commit', '-m', 'chore: initial scaffold from create-snap-harness'], cwd);
  }
}

function run(cmd: string, args: string[], cwd: string): Promise<void> {
  return new Promise((resolve, reject) => {
    const p = spawn(cmd, args, { cwd, stdio: 'inherit', shell: process.platform === 'win32' });
    p.on('exit', code => code === 0 ? resolve() : reject(new Error(`${cmd} exited ${code}`)));
  });
}
