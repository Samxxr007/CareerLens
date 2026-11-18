const { spawn } = require('child_process');
const fs = require('fs');

let rscript = 'Rscript';
const defaultWinPath = 'D:\\Program Files\\R-4.6.1\\bin\\Rscript.exe';

if (fs.existsSync(defaultWinPath)) {
  rscript = `"${defaultWinPath}"`;
} else if (process.env.RSCRIPT_PATH && fs.existsSync(process.env.RSCRIPT_PATH)) {
  rscript = `"${process.env.RSCRIPT_PATH}"`;
}

console.log(`[CareerLens] Starting R Plumber using: ${rscript}`);
const child = spawn(rscript, ['scripts/start-plumber.R'], { stdio: 'inherit', shell: true });

child.on('exit', (code) => {
  process.exit(code || 0);
});
