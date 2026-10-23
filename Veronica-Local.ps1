$ErrorActionPreference = 'Stop'
[Console]::InputEncoding = [Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
$OutputEncoding = [Console]::OutputEncoding
$api = 'http://127.0.0.1:8765'

function Ensure-Api {
    $engine = 'http://127.0.0.1:8768'
    $keyFile = Join-Path $PSScriptRoot 'engine.key'
    if (-not (Test-Path -LiteralPath $keyFile)) {
        $random = New-Object byte[] 32
        [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($random)
        [IO.File]::WriteAllText($keyFile,([Convert]::ToBase64String($random)),[Text.Encoding]::ASCII)
    }
    try { Invoke-RestMethod "$engine/health" -TimeoutSec 2 | Out-Null }
    catch {
        $exe = Join-Path $PSScriptRoot 'runtime/llama-server.exe'
        $model = Join-Path $PSScriptRoot 'models/Qwen3-4B-Instruct-2507-Q4_K_M.gguf'
        if (-not (Test-Path -LiteralPath $exe)) { throw 'Motor local não encontrado.' }
        if (-not (Test-Path -LiteralPath $model)) { throw 'Modelo local não encontrado. Consulte o README.' }
        $arguments = '-m "' + $model + '" --host 127.0.0.1 --port 8768 -c 4096 -ngl 0 --api-key-file "' + $keyFile + '" --cors-origins localhost'
        Start-Process -FilePath $exe -ArgumentList $arguments -WorkingDirectory (Split-Path $exe) -WindowStyle Hidden
        $ready = $false
        for ($i=0; $i -lt 80; $i++) {
            Start-Sleep -Milliseconds 500
            try { $status = Invoke-RestMethod "$engine/health" -TimeoutSec 1; if ($status.status -eq 'ok') { $ready = $true; break } } catch {}
        }
        if (-not $ready) { throw 'O modelo local não iniciou. Verifique se o arquivo GGUF foi baixado por completo.' }
    }
    try { Invoke-RestMethod "$api/health" -TimeoutSec 2 | Out-Null; return } catch {}
    $node = Get-Command node.exe -ErrorAction SilentlyContinue
    $nodePath = if ($node) { $node.Source } else { Join-Path $PSScriptRoot 'runtime/node-v24.22.0-win-x64/node.exe' }
    if (-not (Test-Path -LiteralPath $nodePath)) { throw 'Node.js não encontrado. Execute Iniciar-Veronica.cmd para instalar os componentes.' }
    Start-Process -FilePath $nodePath -ArgumentList ('"' + (Join-Path $PSScriptRoot 'api.js') + '"') -WorkingDirectory $PSScriptRoot -WindowStyle Hidden
    for ($i=0; $i -lt 20; $i++) {
        Start-Sleep -Milliseconds 300
        try { Invoke-RestMethod "$api/health" -TimeoutSec 1 | Out-Null; return } catch {}
    }
    throw 'Não foi possível iniciar a API local.'
}

function Open-Target([string]$target) {
    $t = $target.Trim().Trim('"').Trim("'")
    $aliases = @{
        'explorador'='explorer.exe'; 'explorador de arquivos'='explorer.exe';
        'bloco de notas'='notepad.exe'; 'notepad'='notepad.exe';
        'calculadora'='calc.exe'; 'paint'='mspaint.exe';
        'prompt de comando'='cmd.exe'; 'terminal'='wt.exe';
        'powershell'='powershell.exe'; 'gerenciador de tarefas'='taskmgr.exe';
        'configurações'='ms-settings:'; 'configuracoes'='ms-settings:'
    }
    $name = $t.ToLowerInvariant()
    if ($aliases.ContainsKey($name)) { $t = $aliases[$name] }
    if ($t -match '[\r\n]') { throw 'Nome inválido.' }
    if ($t -match '^https?://') { Start-Process $t; return }
    if ($t -match '^[\w.-]+\.[a-z]{2,}(/.*)?$' -and -not (Test-Path -LiteralPath $t)) { Start-Process "https://$t"; return }
    if (Test-Path -LiteralPath $t) { Start-Process -FilePath (Resolve-Path -LiteralPath $t).Path; return }
    try { Start-Process -FilePath $t -ErrorAction Stop; return }
    catch {
        $apps = @(Get-StartApps | Where-Object { $_.Name -ieq $t })
        if ($apps.Count -eq 0) { $apps = @(Get-StartApps | Where-Object { $_.Name.IndexOf($t,[StringComparison]::OrdinalIgnoreCase) -ge 0 }) }
        if ($apps.Count -eq 1) { Start-Process ("shell:AppsFolder\" + $apps[0].AppID); return }
        if ($apps.Count -gt 1) { throw "Encontrei mais de um aplicativo com '$target'. Informe o nome completo." }
        throw "Não encontrei '$target'. Informe o caminho completo, URL ou nome exato do aplicativo."
    }
}

function Resolve-UserPath([string]$target) {
    $t = $target.Trim().Trim('"').Trim("'")
    $t = $t -replace '(?i)\s+(?:na|no)\s+(?:área de trabalho|area de trabalho|desktop)$',''
    if ([string]::IsNullOrWhiteSpace($t) -or $t -match '[\r\n]') { throw 'Nome ou caminho inválido.' }
    if ([IO.Path]::IsPathRooted($t)) { return [IO.Path]::GetFullPath($t) }
    $desktop = [Environment]::GetFolderPath([Environment+SpecialFolder]::DesktopDirectory)
    return [IO.Path]::GetFullPath((Join-Path $desktop $t))
}

function Create-Folder([string]$target) {
    $path = Resolve-UserPath $target
    if (Test-Path -LiteralPath $path) { return "Já existe: $path" }
    New-Item -ItemType Directory -Path $path -ErrorAction Stop | Out-Null
    return "Pasta criada: $path"
}

function Create-File([string]$target,[string]$content) {
    $path = Resolve-UserPath $target
    if (Test-Path -LiteralPath $path) { throw "O arquivo já existe: $path" }
    $parent = Split-Path -Parent $path
    if (-not (Test-Path -LiteralPath $parent -PathType Container)) { throw "A pasta do arquivo não existe: $parent" }
    [IO.File]::WriteAllText($path,$content,[Text.UTF8Encoding]::new($false))
    return "Arquivo criado: $path"
}

function Choose-Access {
    Write-Host 'Veronica: Antes de começar, preciso saber o nível de acesso ao PC:' -ForegroundColor Cyan
    Write-Host '1 - Leve: apenas conversa, sem ações no PC.'
    Write-Host '2 - Médio: abrir apps/sites, criar arquivos e pastas, controlar volume (com confirmação).'
    Write-Host '3 - Total: ações do nível médio e comandos locais via /exec; comandos pedem confirmação.'
    while ($true) {
        $choice = Read-Host 'Escolha 1, 2 ou 3'
        if ($choice -in @('1','leve')) { return 1 }
        if ($choice -in @('2','medio','médio')) { return 2 }
        if ($choice -in @('3','total')) { return 3 }
        Write-Host 'Digite 1, 2 ou 3.'
    }
}

function Save-Access([int]$level) {
    $configPath = Join-Path $PSScriptRoot 'config.json'
    $json = @{ accessLevel=$level } | ConvertTo-Json -Compress
    [IO.File]::WriteAllText($configPath,$json,[Text.UTF8Encoding]::new($false))
}

function Get-SavedAccess {
    $configPath = Join-Path $PSScriptRoot 'config.json'
    if (-not (Test-Path -LiteralPath $configPath)) { return $null }
    try {
        $level = [int]((Get-Content -LiteralPath $configPath -Raw -Encoding UTF8 | ConvertFrom-Json).accessLevel)
        if ($level -in @(1,2,3)) { return $level }
    } catch {}
    return $null
}

function Send-VolumeKey([byte]$key,[int]$times) {
    if (-not ('VeronicaKeys' -as [type])) {
        Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public class VeronicaKeys { [DllImport("user32.dll")] public static extern void keybd_event(byte key, byte scan, uint flags, UIntPtr extra); }'
    }
    for ($i=0; $i -lt $times; $i++) {
        [VeronicaKeys]::keybd_event($key,0,0,[UIntPtr]::Zero)
        [VeronicaKeys]::keybd_event($key,0,2,[UIntPtr]::Zero)
    }
}

function Run-Action($action) {
    switch ($action.type) {
        'open' { Open-Target $action.target; return 'Aberto.' }
        'create_folder' { return Create-Folder $action.target }
        'create_file' { return Create-File $action.target $action.content }
        'volume_up' { Send-VolumeKey 175 1; return 'Volume aumentado.' }
        'volume_down' { Send-VolumeKey 174 1; return 'Volume reduzido.' }
        'volume_mute' { Send-VolumeKey 173 1; return 'Mudo alternado.' }
        'set_volume' { Send-VolumeKey 174 50; Send-VolumeKey 175 ([Math]::Round([int]$action.level / 2)); return "Volume ajustado para aproximadamente $($action.level)%." }
        default { throw 'Ação desconhecida.' }
    }
}

function Invoke-VeronicaChat([string]$json) {
    $bytes = [Text.Encoding]::UTF8.GetBytes($json)
    $request = [Net.HttpWebRequest]::Create("$api/v1/chat/stream")
    $request.Method = 'POST'
    $request.ContentType = 'application/json; charset=utf-8'
    $request.ContentLength = $bytes.Length
    $request.Timeout = 100000
    $request.ReadWriteTimeout = 100000
    $upload = $request.GetRequestStream()
    try { $upload.Write($bytes,0,$bytes.Length) } finally { $upload.Dispose() }
    $response = $request.GetResponse()
    $reader = [IO.StreamReader]::new($response.GetResponseStream(),[Text.Encoding]::UTF8)
    $started = $false
    $final = $null
    try {
        while (($line = $reader.ReadLine()) -ne $null) {
            $part = $line | ConvertFrom-Json
            if ($part.error) { throw $part.error }
            if ($null -ne $part.delta) {
                if (-not $started) { Write-Host '[Veronica] > ' -NoNewline -ForegroundColor Magenta; $started = $true }
                Write-Host $part.delta -NoNewline -ForegroundColor Magenta
            }
            if ($part.final) { $final = $part.final }
        }
    } finally {
        $reader.Dispose()
        $response.Dispose()
        if ($started) { Write-Host '' }
    }
    if (-not $final) { throw 'A API encerrou a resposta sem resultado.' }
    if (-not $started) { Write-Host "[Veronica] > $($final.reply)" -ForegroundColor Magenta }
    return $final
}

function Show-Banner {
    try { $Host.UI.RawUI.WindowTitle = 'Veronica.exe | Neo' } catch {}
    try { $Host.UI.RawUI.BackgroundColor = 'Black' } catch {}
    $width = 68
    $border = '═' * $width
    Write-Host "╔$border╗" -ForegroundColor DarkMagenta
    Write-Host ('║' + ('  >_  Veronica.exe').PadRight($width) + '║') -ForegroundColor Magenta
    Write-Host "╠$border╣" -ForegroundColor DarkMagenta
    $art = @(
        'V   V  EEEEE  RRRR    OOO   N   N  IIIII   CCCC    AAA',
        'V   V  E      R   R  O   O  NN  N    I    C       A   A',
        'V   V  EEEE   RRRR   O   O  N N N    I    C       AAAAA',
        ' V V   E      R  R   O   O  N  NN    I    C       A   A',
        '  V    EEEEE  R   R   OOO   N   N  IIIII   CCCC   A   A'
    )
    Write-Host ('║' + ''.PadRight($width) + '║') -ForegroundColor DarkMagenta
    foreach ($row in $art) { Write-Host ('║  ' + $row.PadRight($width-2) + '║') -ForegroundColor Magenta }
    Write-Host ('║' + ''.PadRight($width) + '║') -ForegroundColor DarkMagenta
    Write-Host ('║' + ('       IA  •  CHEATS  •  CONTROLE LOCAL').PadRight($width) + '║') -ForegroundColor Magenta
    Write-Host "╠$border╣" -ForegroundColor DarkMagenta
    Write-Host ('║' + ('  [Veronica] > Sistema online.').PadRight($width) + '║') -ForegroundColor Magenta
    Write-Host ('║' + ('  [+] Criador: Neo • dev solo.').PadRight($width) + '║') -ForegroundColor Magenta
    Write-Host ('║' + ('  [+] IA local: pronta.').PadRight($width) + '║') -ForegroundColor Magenta
    Write-Host "╚$border╝" -ForegroundColor DarkMagenta
}

function Show-GameWindows {
    $windows = @(Get-Process | Where-Object { $_.MainWindowHandle -ne 0 -and $_.MainWindowTitle } | Sort-Object ProcessName | Select-Object -First 30)
    if ($windows.Count -eq 0) { Write-Host '[Veronica] > Não encontrei janelas abertas.' -ForegroundColor Magenta; return }
    Write-Host '[Veronica] > Janelas abertas (use /jogo PID):' -ForegroundColor Magenta
    foreach ($window in $windows) { Write-Host ("  {0,6}  {1,-22}  {2}" -f $window.Id,$window.ProcessName,$window.MainWindowTitle) -ForegroundColor Magenta }
}

function Save-GameCode([string]$reply,[string]$gameName) {
    $match = [regex]::Match($reply,'(?ms)^```(python|py|cpp|c\+\+|c|javascript|js|csharp|c#)\s*\r?\n(.*?)\r?\n```\s*$')
    if (-not $match.Success) { Write-Host '[Veronica] > A resposta não trouxe um bloco de código completo. Dê mais detalhes e tente novamente.' -ForegroundColor Yellow; return }
    $extension = switch ($match.Groups[1].Value.ToLowerInvariant()) {
        'python' { '.py' } 'py' { '.py' } 'cpp' { '.cpp' } 'c++' { '.cpp' }
        'c' { '.c' } 'javascript' { '.js' } 'js' { '.js' } 'csharp' { '.cs' } 'c#' { '.cs' }
        default { '.txt' }
    }
    $safeName = $gameName -replace '[^a-zA-Z0-9_-]','_'
    $folder = Join-Path (Join-Path $PSScriptRoot 'projetos') $safeName
    $filename = 'cheat-' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff') + $extension
    $path = Join-Path $folder $filename
    $ok = Read-Host "Salvar o código em '$path'? [s/N]"
    if ($ok -notin @('s','S','sim','SIM')) { return }
    New-Item -ItemType Directory -Path $folder -Force | Out-Null
    [IO.File]::WriteAllText($path,$match.Groups[2].Value,[Text.UTF8Encoding]::new($false))
    Write-Host "[Veronica] > Código salvo: $path" -ForegroundColor Magenta
}

Show-Banner
$access = Get-SavedAccess
if ($null -eq $access) { $access = Choose-Access; Save-Access $access }
Ensure-Api
Write-Host "[+] Acesso $access. Digite /ajuda, /acesso ou /sair." -ForegroundColor Magenta
$history = [Collections.Generic.List[object]]::new()
$selectedGame = $null
while ($true) {
    Write-Host 'Você > ' -NoNewline -ForegroundColor Magenta
    $question = Read-Host
    if ($question -in @('/sair','sair','exit')) { break }
    if ($question -eq '/acesso') { $access = Choose-Access; Save-Access $access; continue }
    if ($question -eq '/ajuda') {
        Write-Host 'Exemplos: oi | /jogo | /jogo PID | /cheat descreva o recurso | crie uma pasta Projetos | volume 30 | /exec dir'
        continue
    }
    if ([string]::IsNullOrWhiteSpace($question)) { continue }
    try {
        if ($question -match '^/jogo(?:\s+(.*))?$') {
            $selection = $Matches[1]
            if ([string]::IsNullOrWhiteSpace($selection)) { Show-GameWindows; continue }
            if ($selection -eq 'limpar') { $selectedGame = $null; Write-Host '[Veronica] > Jogo desmarcado.' -ForegroundColor Magenta; continue }
            if ($selection -notmatch '^\d+$') { throw 'Use /jogo para listar e /jogo PID para selecionar.' }
            $process = Get-Process -Id ([int]$selection) -ErrorAction Stop
            if ($process.MainWindowHandle -eq 0 -or -not $process.MainWindowTitle) { throw 'Esse processo não tem uma janela visível.' }
            $selectedGame = @{ id=$process.Id; name=$process.ProcessName; title=$process.MainWindowTitle }
            Write-Host "[Veronica] > Janela selecionada: $($selectedGame.name) — $($selectedGame.title) (PID $($selectedGame.id))." -ForegroundColor Magenta
            continue
        }
        if ($question -match '^/cheat(?:\s+(.+))?$') {
            if ($access -eq 1) { Write-Host '[Veronica] > Use /acesso e escolha nível médio ou total para gerar arquivos.' -ForegroundColor Yellow; continue }
            if (-not $selectedGame) { Write-Host '[Veronica] > Primeiro use /jogo e selecione o PID do jogo aberto.' -ForegroundColor Yellow; continue }
            $requestText = $Matches[1]
            if ([string]::IsNullOrWhiteSpace($requestText)) { Write-Host '[Veronica] > Exemplo: /cheat adicionar controle de velocidade em Python' -ForegroundColor Yellow; continue }
            if (-not (Get-Process -Id $selectedGame.id -ErrorAction SilentlyContinue)) { $selectedGame = $null; throw 'A janela selecionada foi fechada. Use /jogo novamente.' }
            Ensure-Api
            $prompt = "Jogo aberto: $($selectedGame.title). Processo: $($selectedGame.name), PID $($selectedGame.id). Pedido: $requestText. Gere um único arquivo de código em bloco Markdown para esse componente. Marque integrações desconhecidas como TODO."
            $body = @{ message=$prompt; history=@(); mode='game_code' } | ConvertTo-Json -Depth 8 -Compress
            $draft = Invoke-VeronicaChat $body
            Save-GameCode $draft.reply $selectedGame.name
            continue
        }
        if ($question -match '^/exec(?:\s+(.+))?$') {
            if ($access -ne 3) { Write-Host 'Veronica: /exec exige acesso total. Digite /acesso para mudar.' -ForegroundColor Yellow; continue }
            $command = $Matches[1]
            if ([string]::IsNullOrWhiteSpace($command) -or $command.Length -gt 2048 -or $command -match '[\r\n]') { throw 'Use /exec seguido de um comando em uma linha (até 2048 caracteres).' }
            $ok = Read-Host "Executar no seu Windows: $command ? [s/N]"
            if ($ok -in @('s','S','sim','SIM')) { & cmd.exe /d /s /c $command }
            continue
        }
        $body = @{ message=$question; history=$history.ToArray() } | ConvertTo-Json -Depth 8 -Compress
        $result = $null
        for ($attempt=1; $attempt -le 2; $attempt++) {
            Ensure-Api
            try {
                $result = Invoke-VeronicaChat $body
                break
            } catch {
                if ($attempt -eq 2 -or $_.Exception.Message -notmatch 'conectar|connection|recusada|refused') { throw }
                Start-Sleep -Milliseconds 500
            }
        }
        if ($result.action) {
            if ($access -eq 1) { Write-Host 'Veronica: ação bloqueada pelo acesso leve. Use /acesso para mudar.' -ForegroundColor Yellow; continue }
            $targetLabel = if ($result.action.target) { $result.action.target } elseif ($null -ne $result.action.level) { "$($result.action.level)%" } else { 'PC' }
            $ok = Read-Host "Executar '$($result.action.type)' em '$targetLabel'? [s/N]"
            if ($ok -in @('s','S','sim','SIM')) {
                $done = Run-Action $result.action
                Write-Host "[Veronica] > $done" -ForegroundColor Magenta
            }
        } else {
            $history.Add(@{ role='user'; content=$question })
            $history.Add(@{ role='assistant'; content=$result.reply })
            if ($history.Count -gt 24) { $history.RemoveRange(0,$history.Count-24) }
        }
    } catch {
        $detail = $null
        if ($_.ErrorDetails.Message) { try { $detail = $_.ErrorDetails.Message | ConvertFrom-Json } catch {} }
        if ($detail.error) { Write-Host "Erro: $($detail.error)" -ForegroundColor Red }
        else { Write-Host "Erro: $($_.Exception.Message)" -ForegroundColor Red }
    }
}
