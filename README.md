# Veronica

Assistente local para **Windows 10/11 x64**, criada por **Neo, dev solo**. Conversa no terminal com personalidade hacker descontraída, responde perguntas usando um modelo que roda no próprio PC e pode abrir aplicativos, sites, arquivos e pastas. Também cria pastas e arquivos após confirmação. Não usa API paga nem exige uma chave OpenAI. As respostas do modelo aparecem enquanto são geradas.

O terminal usa uma moldura roxa com **VERONICA** em ASCII art, inspirada no visual neon. As saudações variam a cada "oi" e sempre mencionam Neo como dev solo.

## Iniciar

1. Baixe o projeto e extraia a pasta.
2. Dê dois cliques em `Iniciar-Veronica.cmd`.
3. Na primeira execução, o instalador baixa Node.js portátil, llama.cpp e o modelo Qwen (aproximadamente 2,6 GB no total). É necessária internet apenas para essa instalação. Recomenda-se pelo menos 8 GB de RAM.
4. Escolha o nível de acesso ao PC. Depois, use a Veronica sem internet. Digite `/ajuda`, `/acesso` ou `/sair`.

## Níveis de acesso

- **Leve (1):** conversa, sem ações no PC.
- **Médio (2):** abre aplicativos, sites e arquivos; cria arquivos e pastas; controla o volume. Cada ação pede confirmação.
- **Total (3):** tudo do nível médio e comandos locais com `/exec comando`. Comandos pedem confirmação e rodam com as permissões da conta Windows atual; a Veronica não ganha privilégios de administrador automaticamente.

O nível escolhido fica salvo localmente em `config.json`, então a Veronica pergunta apenas na primeira abertura. Use `/acesso` para mudar e salvar outro nível. Para respostas mais longas, peça "passo a passo" ou "detalhadamente"; elas levam mais tempo para gerar.

Exemplos:

```text
oi
quem te criou?
me explique como funciona um jogo em Python
como criar um cheat de vidas infinitas no meu jogo em Python?
crie um cheat de vidas infinitas para meu jogo em Python
como montar um laboratório local para testar a segurança de uma aplicação web?
crie uma pasta Projetos
crie um arquivo notas.txt com texto Olá mundo
abra o explorador de arquivos
abra https://example.com
abra C:\caminho\arquivo.txt
volume 30
/exec dir
/jogo
/jogo 1234
/cheat adicionar controle de velocidade em Python
```

Nomes simples de pastas e arquivos são criados na **Área de Trabalho**. Use um caminho completo para outro lugar. Ela não substitui arquivos existentes. Cada ação no PC pede confirmação. O volume por porcentagem é aproximado, em passos de cerca de 2%.

## Modo de jogo aberto

1. Abra o jogo e deixe a janela aberta.
2. Digite `/jogo` para listar janelas e processos; selecione o PID mostrado com `/jogo PID`.
3. Digite `/cheat` seguido do componente que quer desenvolver e da linguagem, por exemplo `/cheat criar um módulo de velocidade em Python`.
4. A Veronica gera código e pergunta antes de salvá-lo em `projetos/NOME_DO_PROCESSO/`. Cada tentativa cria um arquivo novo, preservando os anteriores.

Esse modo usa o título da janela e o nome do processo como contexto. A janela aberta, sozinha, não fornece offsets, APIs internas, código-fonte nem uma forma garantida de integrar o arquivo ao jogo. A Veronica não injeta código nem executa o arquivo gerado automaticamente. Para adaptar o resultado, informe versão do jogo, linguagem e dados técnicos disponíveis.

## API local

O programa oferece `GET http://127.0.0.1:8765/health`, `POST http://127.0.0.1:8765/v1/chat` e `POST http://127.0.0.1:8765/v1/chat/stream` (NDJSON). Envie `{"message":"oi","history":[]}`; a resposta traz `reply`, `source` e, quando aplicável, uma sugestão `action`. A API **não executa** essa ação: o terminal mostra e confirma antes de fazê-la. As portas 8765 e 8768 só escutam no próprio computador.

## Repositório privado e instalação

Use um repositório **privado** no GitHub. Publique **somente os arquivos de código** ou a pasta `Veronica-GitHub` preparada para distribuição. Não publique `Veronica.key`, `engine.key`, `config.json`, `projetos/`, `models/` nem `runtime/`. O `.gitignore` impede que esses arquivos entrem em commits comuns, mas não protege uploads manuais de pastas inteiras. A cópia `Veronica-GitHub` já exclui todos eles.

Quem tiver acesso ao repositório pode usar **Code → Download ZIP** ou `git clone URL_DO_REPOSITORIO`, extrair a pasta e abrir `Iniciar-Veronica.cmd`. Na primeira execução, o instalador baixa os componentes locais verificados por SHA-256. Depois disso, funciona sem chave de API paga. O nível de acesso é perguntado uma vez por instalação.

Um repositório privado limita quem vê o código; qualquer pessoa que receba os arquivos pode guardá-los ou copiá-los. Não há proteção técnica que torne um programa distribuído impossível de copiar ou modificar.

O modelo pode errar e não conhece notícias ou informações atualizadas. A versão atual controla o PC por comandos explícitos para abrir e criar; ela não interpreta livremente qualquer tarefa gráfica.

A Veronica ajuda com programação, mods e cheats de jogos, ajustes em dispositivos próprios e estudos de segurança em sistemas sob sua autorização. Seu motor de linguagem é o modelo aberto Qwen; Neo criou a aplicação e a personalidade, não treinou o modelo base do zero.

## Componentes

- [llama.cpp](https://github.com/ggml-org/llama.cpp), binário local sob licença MIT.
- [Qwen3-4B-Instruct-2507-GGUF](https://huggingface.co/unsloth/Qwen3-4B-Instruct-2507-GGUF), modelo local sob Apache 2.0.
- [Node.js](https://nodejs.org/), runtime portátil da API local.

As licenças de terceiros acompanham o pacote de código. O instalador verifica SHA-256 dos downloads.
O código da Veronica é proprietário; consulte `LICENSE`. As licenças dos componentes de terceiros continuam válidas.
