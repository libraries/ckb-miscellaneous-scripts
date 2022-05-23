N = 0x1a0111ea397fe69a_4b1ba7b6434bacd7_64774b84f38512bf_6730d2a0f6b0f624_1eabfffeb153ffff_b9feffffffffaaab
R = 2 ** 384

def extend_gcd(a, b):
    # https://en.wikipedia.org/wiki/Extended_Euclidean_algorithm
    previous_x, x = 1, 0
    previous_y, y = 0, 1
    while b:
        q = a // b
        x, previous_x = previous_x - q * x, x
        y, previous_y = previous_y - q * y, y
        a, b = b, a % b
    return a, previous_x, previous_y

_, RP, NP = extend_gcd(R, N)
R_INVERSE = RP + N
N_INVERSE = -1 * (NP - R)
print('R', hex(R))
print('N', hex(N))
print('R_INVERSE', hex(R_INVERSE)) # 0x14fec701e8fb0ce9ed5e64273c4f538b1797ab1458a88de9343ea97914956dc87fe11274d898fafbf4d38259380b4820
print('N_INVERSE', hex(N_INVERSE)) # 0xceb06106feaafc9468b316fee268cf5819ecca0e8eb2db4c16ef2ef0c8e30b48286adb92d9d113e889f3fffcfffcfffd
R_POW2 = R * R % N

def redc(T):
    # REDC(T) = TR⁻¹ % N
    assert 0 <= T < R * N
    m = (T * N_INVERSE) % R
    t = (T + m * N) // R
    if t >= N:
        return t - N
    return t

def conv(x):
    return redc(x * R_POW2)

a = 0x175fa65f52ecf2b690b040c2e561fe2b751217df5fa1f458eb8f1b30c06bc9e77714d45d45f8a53eebc0db8841f441b7
b = 0x0c696ece5aceee6c785b07028b4d5577929928a2ef4defeeea826cba44a3f38f00000000000000000000000000000000
r = redc(a * b)
print(hex(r))
