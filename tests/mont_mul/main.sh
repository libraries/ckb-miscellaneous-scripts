set -ex

GCC=/home/ubuntu/app/riscv-ckb/bin/riscv64-unknown-linux-gnu-gcc
RUNNER=/home/ubuntu/src/ckb-vm-cli/target/release/ckb-vm-b-cli

$GCC -fPIC -O3 -nostdinc -nostdlib -nostartfiles -fvisibility=hidden -fno-builtin-printf \
    -I deps/ckb-c-stdlib -I deps/ckb-c-stdlib/libc \
    -o /tmp/main tests/mont_mul/main.c
$RUNNER --bin /tmp/main

$GCC \
    -fPIC -O3 -nostdinc -nostdlib -nostartfiles -fvisibility=hidden -fno-builtin-printf \
    -I deps/ckb-c-stdlib -I deps/ckb-c-stdlib/libc \
    -o /tmp/main tests/mont_mul/main_asm.c build/blst_mul_mont_384.o
$RUNNER --bin /tmp/main

rm -f build/blst_mul_mont_384_rvv.o
make build/blst_mul_mont_384_rvv.o
$GCC \
    -fPIC -O3 -nostdinc -nostdlib -nostartfiles -fvisibility=hidden -fno-builtin-printf \
    -I deps/ckb-c-stdlib -I deps/ckb-c-stdlib/libc \
    -o /tmp/main tests/mont_mul/main_rvv.c build/blst_mul_mont_384_rvv.o
$RUNNER --bin /tmp/main
