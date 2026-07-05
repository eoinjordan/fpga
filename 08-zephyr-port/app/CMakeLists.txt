# Build with the repo as an extra module so the board + driver are found:
#   west build -b tangnano20k_semrv 08-zephyr-port/app -- \
#     -DZEPHYR_EXTRA_MODULES=<abs path>/08-zephyr-port
cmake_minimum_required(VERSION 3.20.0)
find_package(Zephyr REQUIRED HINTS $ENV{ZEPHYR_BASE})
project(semnpu_sample)

target_sources(app PRIVATE src/main.c)
