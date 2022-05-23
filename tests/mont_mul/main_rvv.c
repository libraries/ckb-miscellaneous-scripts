#define CKB_C_STDLIB_PRINTF
#include <stdio.h>
#include <stdint.h>
#include "ckb_syscalls.h"

typedef unsigned __int128 llimb_t;
typedef uint64_t limb_t;
const uint64_t LIMB_T_BITS = 64;

void blst_mul_mont_384_rvv(limb_t ret[], const limb_t a[], const limb_t b[], const limb_t n[], const limb_t np1[], const uint64_t size);
void mul_mont_384(limb_t ret[], const limb_t a[], const limb_t b[], const limb_t p[], limb_t n0) {
    const limb_t A[8] = {a[0], a[1], a[2], a[3], a[4], a[5], 0, 0};
    const limb_t B[8] = {b[0], b[1], b[2], b[3], b[4], b[5], 0, 0};
    const limb_t n[8] = {0xb9feffffffffaaab, 0x1eabfffeb153ffff, 0x6730d2a0f6b0f624, 0x64774b84f38512bf, 0x4b1ba7b6434bacd7, 0x1a0111ea397fe69a, 0, 0};
    const limb_t n_reverse[8] = {0x89f3fffcfffcfffd, 0x286adb92d9d113e8, 0x16ef2ef0c8e30b48, 0x19ecca0e8eb2db4c, 0x68b316fee268cf58, 0xceb06106feaafc94, 0, 0};
    limb_t new_ret[8] = {};
    blst_mul_mont_384_rvv(new_ret, A, B, n, n_reverse, 1);
    ret[0] = new_ret[0];
    ret[1] = new_ret[1];
    ret[2] = new_ret[2];
    ret[3] = new_ret[3];
    ret[4] = new_ret[4];
    ret[5] = new_ret[5];
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
