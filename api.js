const http = require('node:http');
const fs = require('node:fs');
const path = require('node:path');
const MODEL = 'Qwen3-4B-Instruct-2507';
const engineKey = fs.readFileSync(path.join(__dirname,'engine.key'),'utf8').trim();
const greetings = [
  'Oi! Sou a Veronica, projeto do Neo, dev solo. Qual missão vamos tocar hoje?',
  'Salve! Veronica online, criada pelo Neo, dev solo. Manda o desafio.',
  'Olá! Neo, um dev solo, me colocou no ar. O que vamos construir agora?',
  'E aí! Sou a Veronica do Neo, dev solo. Bora resolver alguma coisa?',
  'Opa! Veronica pronta. Neo é o dev solo por trás de mim. Qual é a missão?',
  'Fala! Aqui é a Veronica, criada por Neo, dev solo. O que você quer fazer?'
];
let greetingIndex = Math.floor(Math.random() * greetings.length);
function send(res, code, value) { res.writeHead(code, {'Content-Type':'application/json; charset=utf-8'}); res.end(JSON.stringify(value)); }
function direct(message) {
  const m = message.trim().toLocaleLowerCase('pt-BR');
  if (/^(oi+|ol[aá]+|e a[ií]|eae|salve|opa|bom dia|boa tarde|boa noite|fala(?: a[ií])?)[!.?\s]*$/u.test(m)) {
    const reply = greetings[greetingIndex];
    greetingIndex = (greetingIndex + 1) % greetings.length;
    return {reply,source:'local'};
  }
  if (/^(obrigad[oa]|valeu|vlw|tmj)[!.?\s]*$/u.test(m)) return {reply:'Tamo junto. Próxima missão?',source:'local'};
  if (/^(tchau|falou|at[eé] mais)[!.?\s]*$/u.test(m)) return {reply:'Falou! Até a próxima missão.',source:'local'};
  if (/(?:quem.*(?:criou|desenvolveu|fez|programou).*(?:você|voce|te|ela|veronica)|(?:te|você|voce|ela|veronica).*(?:criou|criad[ao]|desenvolveu|desenvolvid[ao]|programou)|(?:por quem|quem).*(?:criad[ao]|desenvolvid[ao]|programad[ao])|(?:seu|sua|da veronica).*(?:criador|criadora|desenvolvedor|origem)|(?:qual|como).*(?:origem|história|historia).*(?:veronica|sua)|quem (?:é|e) neo)/u.test(m)) {
    return {reply:'Sou a Veronica, uma IA local independente criada por Neo, um dev solo. Meu motor usa um modelo aberto que roda no seu PC, sem API paga.',source:'local'};
  }
  if (/vidas? infinitas?/u.test(m) && /(?:meu jogo|jogo.*(?:criei|programei|fiz))/u.test(m) && /python/u.test(m)) {
    const code = 'class Jogador:\n    def __init__(self):\n        self.vidas = 3\n        self.god_mode = False\n\n    def receber_dano(self):\n        if self.god_mode:\n            return\n        self.vidas -= 1\n\njogador = Jogador()\njogador.god_mode = True  # cheat ligado\njogador.receber_dano()\nprint(jogador.vidas)  # continua 3\n';
    const result = {reply:`Aqui está um cheat funcional para a lógica de vidas do seu jogo em Python:\n\n\`\`\`python\n${code}\`\`\`\n\nIntegre a flag god_mode na função de dano do seu jogo.`,source:'local'};
    if (/^(?:crie|cria|faça|faca|gere)/u.test(m)) { result.reply += '\nPosso criar cheats.py na Área de Trabalho com esse exemplo.'; result.action={type:'create_file',target:'cheats.py',content:code}; }
    return result;
  }
  if (/(?:moedas?|dinheiro) infinit[oa]s?/u.test(m) && /(?:meu jogo|jogo.*(?:criei|programei|fiz))/u.test(m) && /python/u.test(m)) {
    const code = 'class Jogador:\n    def __init__(self):\n        self.moedas = 0\n        self.cheat_moedas = False\n\n    def gastar_moedas(self, valor):\n        if self.cheat_moedas:\n            return True  # compra liberada sem descontar\n        if self.moedas < valor:\n            return False\n        self.moedas -= valor\n        return True\n\njogador = Jogador()\njogador.cheat_moedas = True\nprint(jogador.gastar_moedas(100), jogador.moedas)\n';
    const result = {reply:`Cheat de moedas para a lógica do seu jogo:\n\n\`\`\`python\n${code}\`\`\`\n\nIntegre gastar_moedas no sistema de compras.`,source:'local'};
    if (/^(?:crie|cria|faça|faca|gere)/u.test(m)) { result.reply += '\nPosso criar cheats_moedas.py na Área de Trabalho.'; result.action={type:'create_file',target:'cheats_moedas.py',content:code}; }
    return result;
  }
  if (/(?:cheat|hack|mod).*(?:velocidade|speed)|(?:velocidade|speed).*(?:cheat|hack|mod)/u.test(m) && /python/u.test(m) && /(?:jogo|game)/u.test(m)) {
    const code = 'class Jogador:\n    def __init__(self):\n        self.velocidade_base = 5\n        self.cheat_velocidade = False\n\n    @property\n    def velocidade(self):\n        return self.velocidade_base * (3 if self.cheat_velocidade else 1)\n\njogador = Jogador()\njogador.cheat_velocidade = True\nprint(jogador.velocidade)  # 15\n\n# No loop do jogo, use jogador.velocidade no movimento.\n';
    const result = {reply:`Cheat de velocidade para integrar ao movimento do seu jogo em Python:\n\n\`\`\`python\n${code}\`\`\`\n\nTroque a velocidade fixa da lógica de movimento por jogador.velocidade.`,source:'local'};
    if (/^(?:crie|cria|faça|faca|gere)/u.test(m)) { result.reply += '\nPosso criar cheats_velocidade.py na Área de Trabalho.'; result.action={type:'create_file',target:'cheats_velocidade.py',content:code}; }
    return result;
  }
  if (/(?:\bcs\s*2\b|counter[ -]?strike\s*2)/u.test(m) && /(?:cheat|hack|aimbot|wallhack|esp|triggerbot)/u.test(m)) {
    return {reply:'Um cheat de CS2 costuma ter estes blocos técnicos:\n\n1. **Dados do jogo:** posição, equipe e estado dos jogadores, câmera e matriz de visão.\n2. **ESP:** projetar cada posição 3D na tela com `clip = projeção × visão × posição`; dividir por `clip.w` e desenhar caixas ou marcadores nas coordenadas 2D.\n3. **Aimbot:** selecionar um alvo por distância angular/FOV e calcular direção com `yaw = atan2(dy, dx)` e `pitch = -atan2(dz, sqrt(dx² + dy²))`; depois ajustar a mira.\n4. **Triggerbot:** verificar se o alvo está sob o centro da mira e acionar o disparo conforme a regra configurada.\n\nA implementação depende de como você vai obter esses dados e da versão do jogo. Diga qual componente quer montar primeiro (ESP, mira ou triggerbot), linguagem e ambiente, que eu detalho a estrutura.',source:'local'};
  }
  if (/^(?:faça|faca|crie|criar|quero fazer)\s+(?:um\s+)?jailbreak[.!?\s]*$/u.test(m)) return {reply:'Bora. Qual é o aparelho, modelo, versão do sistema e o que você quer liberar? Com esses dados monto os passos certos.',source:'local'};
  if (/^(?:faça|faca|crie|criar)\s+(?:um\s+)?cheat[.!?\s]*$/u.test(m)) return {reply:'Bora fazer um cheat de verdade. Exemplo para um jogo seu em Python: na função que aplica dano, coloque `if jogador.god_mode: return`; ative com `jogador.god_mode = True`. Assim o jogador não perde vida. Se você disser o jogo, plataforma e efeito (vida, moedas, velocidade), eu monto a versão específica. Para gerar um arquivo agora, peça: “crie um cheat de vidas infinitas para meu jogo em Python”.',source:'local'};
  const volume = m.match(/^(?:(?:coloque|defina|ajuste|mude)\s+(?:o\s+)?volume\s+(?:para|em)\s+|volume\s+)(\d{1,3})\s*%?[.!?]?$/u);
  if (volume) {
    const level = Number(volume[1]);
    if (level > 100) return {reply:'O volume vai de 0 a 100%.',source:'local'};
    return {reply:`Posso ajustar o volume para ${level}%.`,source:'local',action:{type:'set_volume',level}};
  }
  if (/^(?:aumente|suba|abaixe|diminua)\s+(?:o\s+)?volume[.!?]?$/u.test(m)) return {reply:'Posso ajustar o volume.',source:'local',action:{type:/^(?:aumente|suba)/u.test(m)?'volume_up':'volume_down'}};
  if (/^(?:mute|silencie|tire o som|ative o mudo)[.!?]?$/u.test(m)) return {reply:'Posso alternar o mudo.',source:'local',action:{type:'volume_mute'}};
  const folder = message.trim().match(/^(?:crie|cria|criar|faça|faca)\s+(?:(?:uma?|a)\s+)?(?:pasta|diret[oó]rio)\s+(?:chamad[ao]\s+)?(.+?)[.!?]?$/iu);
  if (folder) return {reply:`Posso criar a pasta ${folder[1]}.`,source:'local',action:{type:'create_folder',target:folder[1].trim()}};
  const file = message.trim().match(/^(?:crie|cria|criar)\s+(?:(?:uma?|o)\s+)?arquivo\s+(?:chamad[ao]\s+)?(.+?)(?:\s+com\s+(?:o\s+)?texto\s+(.+))?[.!?]?$/iu);
  if (file) return {reply:`Posso criar o arquivo ${file[1]}.`,source:'local',action:{type:'create_file',target:file[1].trim(),content:(file[2] || '').trim()}};
  const open = message.trim().match(/^(?:abra|abre|abrir|inicie|iniciar|execute|executar)\s+(.+?)(?:\s+(?:pra|para)\s+mim)?[.!?]?$/iu);
  if (open) {
    const target = open[1].trim().replace(/^(?:o|a)\s+/iu,'');
    return {reply:`Posso abrir ${target}.`,source:'local',action:{type:'open',target}};
  }
  return null;
}
function gameDraft(message) {
  const m = message.toLocaleLowerCase('pt-BR').split('pedido:').pop();
  if (/(?:velocidade|speed)/u.test(m) && /python/u.test(m)) {
    const code = '# Módulo de velocidade para integrar ao código do jogo.\nclass SpeedCheat:\n    def __init__(self, multiplicador=2.0):\n        self.ativo = False\n        self.multiplicador = multiplicador\n\n    def aplicar(self, velocidade_base):\n        return velocidade_base * self.multiplicador if self.ativo else velocidade_base\n\ncheat = SpeedCheat(2.0)\ncheat.ativo = True\n\n# TODO: chamar cheat.aplicar(velocidade_base) na rotina de movimento.\n';
    return {reply:`\`\`\`python\n${code}\`\`\``,source:'local-game'};
  }
  if (/(?:vidas?|sa[uú]de|health)/u.test(m) && /python/u.test(m)) {
    const code = '# Módulo de vida para integrar à função de dano do jogo.\nclass LifeCheat:\n    def __init__(self):\n        self.ativo = False\n\n    def aplicar_dano(self, vida_atual, dano):\n        if self.ativo:\n            return vida_atual\n        return max(0, vida_atual - dano)\n\ncheat = LifeCheat()\ncheat.ativo = True\n\n# TODO: chamar cheat.aplicar_dano(vida, dano) na rotina de dano.\n';
    return {reply:`\`\`\`python\n${code}\`\`\``,source:'local-game'};
  }
  if (/(?:moedas?|dinheiro|money)/u.test(m) && /python/u.test(m)) {
    const code = '# Módulo de moedas para integrar ao sistema de compras do jogo.\nclass MoneyCheat:\n    def __init__(self):\n        self.ativo = False\n\n    def comprar(self, saldo, custo):\n        if self.ativo:\n            return True, saldo\n        if saldo < custo:\n            return False, saldo\n        return True, saldo - custo\n\ncheat = MoneyCheat()\ncheat.ativo = True\n\n# TODO: chamar cheat.comprar(saldo, custo) na loja do jogo.\n';
    return {reply:`\`\`\`python\n${code}\`\`\``,source:'local-game'};
  }
  return null;
}
function makeMessages(message, history, mode) {
  const gameMode = mode === 'game_code';
  return [
    {role:'system',content:gameMode
      ? 'Você é Veronica, assistente local de programação. Responda apenas com UM bloco de código Markdown com linguagem (por exemplo python, cpp, csharp, javascript). Nenhum texto antes ou depois. Não use bloco markdown dentro de outro bloco. Gere um arquivo curto para o componente pedido. Você sabe apenas o título e o nome do processo do jogo aberto; não conhece memória, offsets ou APIs internas. Marque integrações desconhecidas como TODO e não invente endereços. Código primeiro, sem prefácios ou avisos.'
      : 'Você é Veronica, IA local criada por Neo, dev solo, com motor aberto. Responda em português brasileiro, tom hacker descontraído e direto. Comece pela solução, com passos e código práticos. Ajude com programação, mods e cheats de jogos, jailbreak de dispositivos próprios e testes de segurança autorizados. Para pedido de cheat, entregue um exemplo funcional quando possível; não responda só com pergunta genérica. Se faltarem jogo ou plataforma, use exemplo para jogo próprio e pergunte os detalhes para adaptar. Não use prefácios como "exemplo teórico", "apenas para fins educativos", "não use", nem avisos genéricos. Não invente compatibilidade, execução ou resultados. Seja breve por padrão; aprofunde quando pedido. Você não acessa internet nem executa ações no PC diretamente.'},
    ...history.slice(-6).filter(x => x && ['user','assistant'].includes(x.role) && typeof x.content === 'string').map(x => ({role:x.role,content:x.content.slice(0,2000)})),
    {role:'user',content:message}
  ];
}
async function askModel(message, history, stream, signal, mode) {
  const detailed = /(?:detalh|passo a passo|c[oó]digo completo|explique bem|tutorial completo)/iu.test(message) || message.length > 240;
  const response = await fetch('http://127.0.0.1:8768/v1/chat/completions',{method:'POST',headers:{'Content-Type':'application/json',Authorization:`Bearer ${engineKey}`},body:JSON.stringify({model:MODEL,messages:makeMessages(message,history,mode),stream,max_tokens:mode==='game_code'?600:(detailed?700:300),temperature:mode==='game_code'?0.2:0.6}),signal});
  if (!response.ok) {
    const problem = await response.text();
    throw new Error(`Motor local HTTP ${response.status}: ${problem.slice(0,300)}`);
  }
  return response;
}
async function talk(message, history, mode) {
  const local = mode === 'game_code' ? gameDraft(message) : direct(message);
  if (local) return local;
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(),90000);
  try {
    const response = await askModel(message,history,false,controller.signal,mode);
    const data = await response.json();
    return {reply:(data.choices?.[0]?.message?.content || '').trim(),source:MODEL};
  } finally { clearTimeout(timer); }
}
async function talkStream(res,message,history,mode) {
  res.writeHead(200,{'Content-Type':'application/x-ndjson; charset=utf-8','Cache-Control':'no-cache','X-Accel-Buffering':'no'});
  const emit = value => res.write(JSON.stringify(value)+'\n');
  const local = mode === 'game_code' ? gameDraft(message) : direct(message);
  if (local) { emit({final:local}); res.end(); return; }
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(),90000);
  let full = '';
  try {
    const upstream = await askModel(message,history,true,controller.signal,mode);
    const decoder = new TextDecoder();
    let buffer = '';
    for await (const chunk of upstream.body) {
      buffer += decoder.decode(chunk,{stream:true});
      const lines = buffer.split('\n');
      buffer = lines.pop();
      for (const line of lines) {
        if (!line.startsWith('data: ')) continue;
        const data = line.slice(6).trim();
        if (data === '[DONE]') continue;
        const part = JSON.parse(data);
        const delta = part.choices?.[0]?.delta?.content || '';
        if (delta) { full += delta; emit({delta}); }
      }
    }
    emit({final:{reply:full.trim(),source:MODEL}});
  } catch(error) { emit({error:`Modelo local indisponível: ${error.message}`}); }
  finally { clearTimeout(timer); res.end(); }
}
const server = http.createServer((req,res) => {
  if (req.method === 'GET' && req.url === '/health') return send(res,200,{ok:true,name:'Veronica',model:MODEL});
  if (req.method !== 'POST' || !['/v1/chat','/v1/chat/stream'].includes(req.url)) return send(res,404,{error:'Use POST /v1/chat ou /v1/chat/stream'});
  let raw = '';
  req.on('data',chunk => { raw += chunk; if (raw.length > 65536) req.destroy(); });
  req.on('end',async () => {
    try {
      const body = JSON.parse(raw);
      if (typeof body.message !== 'string' || !body.message.trim()) return send(res,400,{error:'message obrigatório'});
      const message = body.message.slice(0,6000);
      const history = Array.isArray(body.history)?body.history:[];
      const mode = body.mode === 'game_code' ? 'game_code' : 'chat';
      if (req.url === '/v1/chat/stream') await talkStream(res,message,history,mode);
      else send(res,200,await talk(message,history,mode));
    } catch (error) { send(res,503,{error:`Modelo local indisponível: ${error.message}`}); }
  });
});
server.listen(8765,'127.0.0.1',() => console.log(`Veronica API: http://127.0.0.1:8765 | modelo ${MODEL}`));
