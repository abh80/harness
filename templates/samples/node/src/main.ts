process.stdin.setEncoding('utf8');
let buf = '';
process.stdin.on('data', d => buf += d);
process.stdin.on('end', () => {
  const name = buf.trim();
  process.stdout.write(`hello, ${name}\n`);
});
