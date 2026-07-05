# Reclones vendor reference repos (vendor/ is gitignored).
$root = Split-Path $PSScriptRoot -Parent
if (-not (Test-Path "$root\vendor\TangNano-20K-example")) {
    git clone --depth 1 https://github.com/sipeed/TangNano-20K-example "$root\vendor\TangNano-20K-example"
}
# Spartan Edge references (docs/schematics + two projects with verified pins)
if (-not (Test-Path "$root\vendor\Spartan-Edge-Accelerator-Board")) {
    git clone --depth 1 https://github.com/SeeedDocument/Spartan-Edge-Accelerator-Board "$root\vendor\Spartan-Edge-Accelerator-Board"
}
if (-not (Test-Path "$root\vendor\sea-graphics")) {
    git clone --depth 1 https://github.com/smartperson/spartan-edge-accelerator-graphical-system "$root\vendor\sea-graphics"
}
if (-not (Test-Path "$root\vendor\sea-bspartan")) {
    git clone --depth 1 https://github.com/mhrtmnn/BSpartan "$root\vendor\sea-bspartan"
}
# Stage 06 references (uncomment when you reach it):
# git clone --depth 1 https://github.com/YosysHQ/picorv32 "$root\vendor\picorv32"
