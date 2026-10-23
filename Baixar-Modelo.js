// Baixa o modelo oficial para a primeira execucao. Usa apenas Node.js, sem npm.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const { Readable } = require('node:stream');
const { pipeline } = require('node:stream/promises');

const modelDir = path.join(__dirname, 'models');
const modelPath = path.join(modelDir, 'Qwen3-4B-Instruct-2507-Q4_K_M.gguf');
const partialPath = `${modelPath}.part`;
const url = 'https://huggingface.co/unsloth/Qwen3-4B-Instruct-2507-GGUF/resolve/a06e946bb6b655725eafa393f4a9745d460374c9/Qwen3-4B-Instruct-2507-Q4_K_M.gguf';
const expectedBytes = 2497281120;
const expectedSha256 = '3605803b982cb64aead44f6c1b2ae36e3acdb41d8e46c8a94c6533bc4c67e597';

function sha256(file) {
  return new Promise((resolve, reject) => {
    const hash = crypto.createHash('sha256');
    fs.createReadStream(file).on('data', chunk => hash.update(chunk)).on('error', reject).on('end', () => resolve(hash.digest('hex')));
  });
}

(async () => {
  fs.mkdirSync(modelDir, { recursive: true });
  if (fs.existsSync(modelPath)) {
    if (fs.statSync(modelPath).size === expectedBytes && await sha256(modelPath) === expectedSha256) {
      console.log('Modelo local verificado.');
      return;
    }
    throw new Error('O modelo existente não passou na verificação. Remova o arquivo GGUF e rode novamente.');
  }
  for (let attempt = 1; attempt <= 100; attempt++) {
    const size = fs.existsSync(partialPath) ? fs.statSync(partialPath).size : 0;
    if (size >= expectedBytes) break;
    try {
      const response = await fetch(url, {
        headers: size ? { Range: `bytes=${size}-` } : {},
        signal: AbortSignal.timeout(300000)
      });
      if (!response.ok || (size && response.status !== 206 && response.status !== 200)) throw new Error(`HTTP ${response.status}`);
      const append = size && response.status === 206;
      await pipeline(Readable.fromWeb(response.body), fs.createWriteStream(partialPath, { flags: append ? 'a' : 'w' }));
      console.log(`Modelo: ${Math.round(fs.statSync(partialPath).size / expectedBytes * 100)}%`);
    } catch (error) {
      console.log(`Tentativa ${attempt}: ${error.message}. Retomando download...`);
      await new Promise(resolve => setTimeout(resolve, 2000));
    }
  }
  if (!fs.existsSync(partialPath) || fs.statSync(partialPath).size !== expectedBytes) throw new Error('Download incompleto. Execute novamente para retomar.');
  if (await sha256(partialPath) !== expectedSha256) throw new Error('Verificação SHA-256 falhou. Não use este modelo.');
  fs.renameSync(partialPath, modelPath);
  console.log('Modelo instalado e verificado.');
})().catch(error => { console.error(error.message); process.exitCode = 1; });
