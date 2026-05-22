# identify.ps1

$env:API_KEY="apik4293"
$env:IBMI_HOST="10.55.10.108"
$env:IBMI_USER="k4293t"
$env:IBMI_PASSWORD="mielee"

Write-Host "IBM i 接続情報セット"

node server.js