.text
.globl blst_mul_mont_384_rvv
.align 4
// a0: ret
// a1: x
// a2: y
// a3: n
// a4: n_reverse
// a5: size
blst_mul_mont_384_rvv:
  vsetvli t0, a5, e512, m1

  vle512.v v1, (a1)     // v1 -> x
  vle512.v v2, (a2)     // v2 -> y
  vle512.v v3, (a3)     // v3 -> n
  vle512.v v4, (a4)     // v4 -> n_reverse

  // T = x * y
  vwmulu.vv v6, v1, v2  // v6 -> x * y

  // m = (T * N⁻¹) % R
  // t = (T + m * N) / R
  // if (N <= t):
  //    t -= N
  vnsrl.wx v5, v6, zero // v5 -> (x * y) % 2^512
  li t1, 128
  vsll.vx v5, v5, t1
  vsrl.vx v5, v5, t1    // v5 -> (x * y) % 2^384

  vwmulu.vv v8, v5, v4
  vnsrl.wx v7, v8, zero
  vsll.vx v7, v7, t1
  vsrl.vx v7, v7, t1    // v7 -> m

  vwmaccu.vv v6, v7, v3
  li t1, 384
  vnsrl.wx v6, v6, t1   // v6 -> t

  vmsleu.vv v0, v3, v6
  vsub.vv v6, v6, v3, v0.t

  vse512.v v6, (a0)
  ret
