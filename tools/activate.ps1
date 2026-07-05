# Dot-source this each session:  . .\tools\activate.ps1
# Puts the OSS CAD Suite and msys2 make on PATH for this shell only.

$ossCad = "$env:USERPROFILE\oss-cad-suite"

if (-not (Test-Path "$ossCad\bin")) {
    Write-Host "OSS CAD Suite not found at $ossCad" -ForegroundColor Red
    Write-Host "See docs\00-dev-environment.md for install steps."
    return
}

$env:PATH = "$ossCad\bin;$ossCad\lib;C:\devkitPro\msys2\usr\bin;$env:PATH"
Write-Host "FPGA toolchain active: $ossCad" -ForegroundColor Green
