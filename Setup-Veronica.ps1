$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
$runtime = Join-Path $PSScriptRoot 'runtime'
$model = Join-Path $PSScriptRoot 'models/Qwen3-4B-Instruct-2507-Q4_K_M.gguf'
New-Item -ItemType Directory -Path $runtime -Force | Out-Null

function Download-VerifiedZip([string]$url,[string]$hash,[string]$destination) {
    $temp = Join-Path $env:TEMP ([IO.Path]::GetRandomFileName() + '.zip')
    try {
        for ($attempt=1; $attempt -le 3; $attempt++) {
            try {
                Write-Host "Baixando $url (tentativa $attempt/3)..."
                Invoke-WebRequest -Uri $url -OutFile $temp -UseBasicParsing
                $actual = (Get-FileHash -LiteralPath $temp -Algorithm SHA256).Hash.ToLowerInvariant()
                if ($actual -ne $hash) { throw 'Hash do download diferente do esperado.' }
                Expand-Archive -LiteralPath $temp -DestinationPath $destination -Force
                return
            } catch {
                if ($attempt -eq 3) { throw }
                Start-Sleep -Seconds 2
            }
        }
    } finally { Remove-Item -LiteralPath $temp -ErrorAction SilentlyContinue }
}

$node = Get-Command node.exe -ErrorAction SilentlyContinue
if ($node) { $nodePath = $node.Source }
else {
    $nodePath = Join-Path $runtime 'node-v24.22.0-win-x64/node.exe'
    if (-not (Test-Path -LiteralPath $nodePath)) {
        Download-VerifiedZip 'https://nodejs.org/dist/v24.22.0/node-v24.22.0-win-x64.zip' 'f9683a19877e12a9b167305c8db71040d812876359de21f0d2e97c3f321f80c3' $runtime
    }
}

$llama = Join-Path $runtime 'llama-server.exe'
if (-not (Test-Path -LiteralPath $llama)) {
    Download-VerifiedZip 'https://github.com/ggml-org/llama.cpp/releases/download/b11840/llama-b11840-bin-win-cpu-x64.zip' 'f805935dec8a6f527bf3d587419865c1cf486ba6a430dc0381ca97aedf0da034' $runtime
}

if (-not (Test-Path -LiteralPath $model)) {
    Write-Host 'Baixando o modelo local (cerca de 2,5 GB). O download pode ser retomado.'
    & $nodePath (Join-Path $PSScriptRoot 'Baixar-Modelo.js')
    if ($LASTEXITCODE -ne 0) { throw 'Falha ao baixar o modelo local.' }
}
Write-Host 'Veronica instalada e pronta.'
