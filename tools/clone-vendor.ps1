# Reclones vendor reference repos (vendor/ is gitignored).
$root = Split-Path $PSScriptRoot -Parent
if (-not (Test-Path "$root\vendor\TangNano-20K-example")) {
    git clone --depth 1 https://github.com/sipeed/TangNano-20K-example "$root\vendor\TangNano-20K-example"
}
# Stage 06 references (uncomment when you reach it):
# git clone --depth 1 https://github.com/YosysHQ/picorv32 "$root\vendor\picorv32"
