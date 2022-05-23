#define CKB_C_STDLIB_PRINTF
#include <stdio.h>
#include <stdint.h>
#include "ckb_syscalls.h"

typedef unsigned __int128 llimb_t;
typedef uint64_t limb_t;
const uint64_t LIMB_T_BITS = 64;

void blst_mul_mont_384(limb_t ret[], const limb_t a[], const limb_t b[], const limb_t p[], limb_t n0);
void mul_mont_384(limb_t ret[], const limb_t a[], const limb_t b[], const limb_t p[], limb_t n0) {
    blst_mul_mont_384(ret, a, b, p, n0);
}

int main() {
    limb_t p[] = {0xb9feffffffffaaab, 0x1eabfffeb153ffff, 0x6730d2a0f6b0f624, 0x64774b84f38512bf, 0x4b1ba7b6434bacd7, 0x1a0111ea397fe69a};
    limb_t n0 = 0x89f3fffcfffcfffd;
    limb_t ret[6];
    limb_t a[6] = {0x1};
    limb_t b[6] = {0x2};

    mul_mont_384(ret, a, b, p, n0);
    printf("%016lx%016lx%016lx%016lx%016lx%016lx\n", ret[5], ret[4], ret[3], ret[2], ret[1], ret[0]);
}
