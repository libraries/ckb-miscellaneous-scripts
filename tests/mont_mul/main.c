#define CKB_C_STDLIB_PRINTF
#include <stdio.h>
#include <stdint.h>
#include "ckb_syscalls.h"

typedef unsigned __int128 llimb_t;
typedef uint64_t limb_t;
const uint64_t LIMB_T_BITS = 64;

void mul_mont_n(limb_t ret[], const limb_t a[], const limb_t b[],
                       const limb_t p[], limb_t n0, size_t n)
{
    llimb_t limbx;
    limb_t mask, borrow, mx, hi, tmp[n+1], carry;
    size_t i, j;

    for (mx=b[0], hi=0, i=0; i<n; i++) {
        limbx = (mx * (llimb_t)a[i]) + hi;
        tmp[i] = (limb_t)limbx;
        hi = (limb_t)(limbx >> LIMB_T_BITS);
    }
    mx = n0*tmp[0];
    tmp[i] = hi;

    for (carry=0, j=0; ; ) {
        limbx = (mx * (llimb_t)p[0]) + tmp[0];
        hi = (limb_t)(limbx >> LIMB_T_BITS);
        for (i=1; i<n; i++) {
            limbx = (mx * (llimb_t)p[i] + hi) + tmp[i];
            tmp[i-1] = (limb_t)limbx;
            hi = (limb_t)(limbx >> LIMB_T_BITS);
        }
        limbx = tmp[i] + (hi + (llimb_t)carry);
        tmp[i-1] = (limb_t)limbx;
        carry = (limb_t)(limbx >> LIMB_T_BITS);

        if (++j==n)
            break;

        for (mx=b[j], hi=0, i=0; i<n; i++) {
            limbx = (mx * (llimb_t)a[i] + hi) + tmp[i];
            tmp[i] = (limb_t)limbx;
            hi = (limb_t)(limbx >> LIMB_T_BITS);
        }
        mx = n0*tmp[0];
        limbx = hi + (llimb_t)carry;
        tmp[i] = (limb_t)limbx;
        carry = (limb_t)(limbx >> LIMB_T_BITS);
    }

    for (borrow=0, i=0; i<n; i++) {
        limbx = tmp[i] - (p[i] + (llimb_t)borrow);
        ret[i] = (limb_t)limbx;
        borrow = (limb_t)(limbx >> LIMB_T_BITS) & 1;
    }

    mask = carry - borrow;

    for(i=0; i<n; i++)
        ret[i] = (ret[i] & ~mask) | (tmp[i] & mask);
}

void mul_mont_384(limb_t ret[], const limb_t a[], const limb_t b[], const limb_t p[], limb_t n0) {
    mul_mont_n(ret, a, b, p, n0, 6);
}

int main(int argc, const char *argv[]) {
    limb_t p[] = {0xb9feffffffffaaab, 0x1eabfffeb153ffff, 0x6730d2a0f6b0f624, 0x64774b84f38512bf, 0x4b1ba7b6434bacd7, 0x1a0111ea397fe69a};
    limb_t n0 = 0x89f3fffcfffcfffd;
    limb_t ret[6];
    limb_t a[6] = {0x1};
    limb_t b[6] = {0x2};

    mul_mont_384(ret, a, b, p, n0);
    printf("%016lx%016lx%016lx%016lx%016lx%016lx\n", ret[5], ret[4], ret[3], ret[2], ret[1], ret[0]);
}
