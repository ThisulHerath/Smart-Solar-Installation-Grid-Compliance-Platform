$ErrorActionPreference = 'Stop'

$env:PUB_CACHE = 'D:\dev\pub-cache'
$flutter = 'D:\dev\flutter\bin\flutter.bat'

if (-not (Test-Path -LiteralPath $flutter)) {
    throw "Flutter SDK was not found at D:\dev\flutter"
}

& $flutter pub get
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Write-Host ''
Write-Host 'Starting Smart Solar at http://localhost:4173' -ForegroundColor Cyan
Write-Host 'Keep this terminal open. Press r for hot reload after saving code.' -ForegroundColor Yellow
Write-Host 'Press R for a full hot restart, or q to stop.' -ForegroundColor DarkGray
Write-Host ''

& $flutter run -d chrome --web-port 4173

