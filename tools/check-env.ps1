# Verifies the toolchain is installed and on PATH.
$ok = $true
$tools = @(
    @{ name = 'iverilog';            why = 'simulation (compile)' },
    @{ name = 'vvp';                 why = 'simulation (run)' },
    @{ name = 'gtkwave';             why = 'waveform viewer' },
    @{ name = 'yosys';               why = 'synthesis' },
    @{ name = 'nextpnr-himbaechel';  why = 'place & route (Gowin)' },
    @{ name = 'gowin_pack';          why = 'bitstream packing' },
    @{ name = 'openFPGALoader';      why = 'board programming' },
    @{ name = 'python';              why = 'golden models' },
    @{ name = 'make';                why = 'build automation' }
)
foreach ($t in $tools) {
    $c = Get-Command $t.name -ErrorAction SilentlyContinue
    if ($c) {
        Write-Host ("  OK      {0,-20} {1}" -f $t.name, $c.Source) -ForegroundColor Green
    } else {
        Write-Host ("  MISSING {0,-20} needed for: {1}" -f $t.name, $t.why) -ForegroundColor Red
        $ok = $false
    }
}
if ($ok) {
    Write-Host "`nEnvironment ready. Try: cd 01-hdl-basics; make" -ForegroundColor Green
} else {
    Write-Host "`nRun '. .\tools\activate.ps1' first, or see docs\00-dev-environment.md" -ForegroundColor Yellow
}
