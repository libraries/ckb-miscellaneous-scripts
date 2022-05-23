# TARGET := riscv64-unknown-linux-gnu
TARGET := /home/ubuntu/app/riscv-ckb/bin/riscv64-unknown-linux-gnu
CC := $(TARGET)-gcc
LD := $(TARGET)-gcc
OBJCOPY := $(TARGET)-objcopy
CFLAGS := -fPIC -O3 -nostdinc -nostdlib -nostartfiles -fvisibility=hidden -I deps/ckb-c-stdlib -I deps/ckb-c-stdlib/libc -I deps -I deps/ckb-c-stdlib/molecule -I c -I build -I deps/secp256k1/src -I deps/secp256k1 -Wall -Werror -Wno-nonnull -Wno-nonnull-compare -Wno-unused-function -g
LDFLAGS := -Wl,-static -fdata-sections -ffunction-sections -Wl,--gc-sections
SECP256K1_SRC := deps/secp256k1/src/ecmult_static_pre_context.h

CFLAGS_MBEDTLS := -fPIC -Os -fno-builtin-printf -nostdinc -nostdlib -nostartfiles -fvisibility=hidden -fdata-sections -ffunction-sections -I deps/ckb-c-stdlib -I deps/ckb-c-stdlib/molecule -I deps/ckb-c-stdlib/libc -I deps/mbedtls/include -Wall -Werror -Wno-nonnull -Wno-nonnull-compare -Wno-unused-function -g
LDFLAGS_MBEDTLS := -Wl,-static -Wl,--gc-sections
PASSED_MBEDTLS_CFLAGS := -Os -fPIC -nostdinc -nostdlib -DCKB_DECLARATION_ONLY -I ../../ckb-c-stdlib/libc -fdata-sections -ffunction-sections

CFLAGS_BLST := -fno-builtin-printf -Ideps/blst/bindings $(subst ckb-c-stdlib,ckb-c-stdlib-202106,$(CFLAGS))
# CKB_VM_CLI := ckb-vm-b-cli
CKB_VM_CLI := /home/ubuntu/src/ckb-vm-cli/target/release/ckb-vm-b-cli


MOLC := moleculec
MOLC_VERSION := 0.7.0

# docker pull nervos/ckb-riscv-gnu-toolchain:gnu-bionic-20191012
BUILDER_DOCKER := nervos/ckb-riscv-gnu-toolchain@sha256:aae8a3f79705f67d505d1f1d5ddc694a4fd537ed1c7e9622420a470d59ba2ec3

all: build/htlc build/secp256k1_blake2b_sighash_all_lib.so build/or build/simple_udt build/secp256k1_blake2b_sighash_all_dual build/and build/open_transaction build/rsa_sighash_all blst-demo

all-via-docker:
	docker run --rm -v `pwd`:/code ${BUILDER_DOCKER} bash -c "cd /code && make"

build/htlc: c/htlc.c build/secp256k1_blake2b_sighash_all_lib.h
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $<
	$(OBJCOPY) --only-keep-debug $@ $@.debug
	$(OBJCOPY) --strip-debug --strip-all $@

build/secp256k1_blake2b_sighash_all_lib.h: build/generate_data_hash build/secp256k1_blake2b_sighash_all_lib.so
	$< build/secp256k1_blake2b_sighash_all_lib.so secp256k1_blake2b_sighash_all_data_hash > $@

build/secp256k1_blake2b_sighash_all_dual: c/secp256k1_blake2b_sighash_all_dual.c build/secp256k1_data_info.h
	$(CC) $(CFLAGS) $(LDFLAGS) -fPIC -fPIE -pie -Wl,--dynamic-list c/dual.syms -o $@ $<
	$(OBJCOPY) --only-keep-debug $@ $@.debug
	$(OBJCOPY) --strip-debug --strip-all $@

build/secp256k1_blake2b_sighash_all_lib.so: c/secp256k1_blake2b_sighash_all_lib.c build/secp256k1_data_info.h
	$(CC) $(CFLAGS) $(LDFLAGS) -shared -o $@ $<
	$(OBJCOPY) --only-keep-debug $@ $@.debug
	$(OBJCOPY) --strip-debug --strip-all $@

build/secp256k1_data_info.h: build/dump_secp256k1_data
	$<

build/generate_data_hash: deps/generate_data_hash.c
	gcc -O3 -I deps -o $@ $<

build/dump_secp256k1_data: deps/dump_secp256k1_data.c $(SECP256K1_SRC)
	gcc -O3 -I deps/secp256k1/src -I deps/secp256k1 -o $@ $<

build/or: c/or.c c/or.h
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $<
	$(OBJCOPY) --only-keep-debug $@ $@.debug
	$(OBJCOPY) --strip-debug --strip-all $@

build/and: c/and.c c/or.h
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $<
	$(OBJCOPY) --only-keep-debug $@ $@.debug
	$(OBJCOPY) --strip-debug --strip-all $@

build/open_transaction: c/open_transaction.c
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $<
	$(OBJCOPY) --only-keep-debug $@ $@.debug
	$(OBJCOPY) --strip-debug --strip-all $@

build/simple_udt: c/simple_udt.c
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $<
	$(OBJCOPY) --only-keep-debug $@ $@.debug
	$(OBJCOPY) --strip-debug --strip-all $@

deps/mbedtls/library/libmbedcrypto.a:
	cp deps/mbedtls-config-template.h deps/mbedtls/include/mbedtls/config.h
	make -C deps/mbedtls/library CC=${CC} LD=${LD} CFLAGS="${PASSED_MBEDTLS_CFLAGS}" libmbedcrypto.a

build/impl.o: deps/ckb-c-stdlib/libc/src/impl.c
	$(CC) -c $(filter-out -DCKB_DECLARATION_ONLY, $(CFLAGS_MBEDTLS)) $(LDFLAGS_MBEDTLS) -o $@ $^

rsa_sighash_all-via-docker:
	docker run --rm -v `pwd`:/code ${BUILDER_DOCKER} bash -c "cd /code && make build/rsa_sighash_all"

build/rsa_sighash_all: c/rsa_sighash_all.c deps/mbedtls/library/libmbedcrypto.a
	$(CC) $(CFLAGS_MBEDTLS) $(LDFLAGS_MBEDTLS) -D__SHARED_LIBRARY__ -fPIC -fPIE -pie -Wl,--dynamic-list c/rsa.syms -o $@ $^
	$(OBJCOPY) --only-keep-debug $@ $@.debug
	$(OBJCOPY) --strip-debug --strip-all $@

simulator/build/rsa_sighash_all_test: simulator/rsa_sighash_all_usesim.c deps/mbedtls/library/libmbedcrypto.a
	riscv64-unknown-elf-gcc -DRSA_RUN_TEST $(CFLAGS_MBEDTLS) ${LDFLAGS_MBEDTLS} -o $@ $^

rsa_sighash_clean:
	make -C deps/mbedtls/library clean
	rm -f build/rsa_sighash_all
	rm -f build/rsa_sighash_all_test
	rm -f build/*.o

$(SECP256K1_SRC):
	cd deps/secp256k1 && \
		./autogen.sh && \
		CC=$(CC) LD=$(LD) ./configure --with-bignum=no --enable-ecmult-static-precomputation --enable-endomorphism --enable-module-recovery --host=$(TARGET) && \
		make src/ecmult_static_pre_context.h src/ecmult_static_context.h

blst-apply-patch:
	cd deps/blst; git apply ../../blst/blst.patch || echo "applying patch: ignore errors if applied."

blst-demo: blst-apply-patch build/blst-demo-no-asm build/blst-demo build/blst-demo-rvv build/bls12_381_sighash_all

build/bls12_381_sighash_all: c/bls12_381_sighash_all.c build/server-asm.o build/blst_mul_mont_384.o build/blst_mul_mont_384x.o
	$(CC) $(CFLAGS_BLST) ${LDFLAGS} -o $@ $^
	$(OBJCOPY) --only-keep-debug $@ $@.debug
	$(OBJCOPY) --strip-debug --strip-all $@

build/server.o: deps/blst/src/server.c deps/blst/src/no_asm.h
	$(CC) -c -DCKB_DECLARATION_ONLY $(CFLAGS_BLST)  $(LDFLAGS) -o $@ $<

build/server-asm.o: deps/blst/src/server.c deps/blst/src/no_asm.h
	$(CC) -c -DUSE_MUL_MONT_384_ASM -DCKB_DECLARATION_ONLY $(CFLAGS_BLST) $(LDFLAGS) -o $@ $<

build/server-asm-rvv.o: deps/blst/src/server.c deps/blst/src/no_asm.h
	$(CC) -c -DUSE_MUL_MONT_384_ASM -DUSE_RVV -DCKB_DECLARATION_ONLY $(CFLAGS_BLST) $(LDFLAGS) -o $@ $<

build/blst_mul_mont_384.o: blst/blst_mul_mont_384.riscv.S
	$(CC) -c -DCKB_DECLARATION_ONLY $(CFLAGS_BLST) -o $@ $^

build/blst_mul_mont_384_rvv_gen.S: blst/blst_mul_mont_384_rvv.riscv.S
	rvv-as $^ > $@

build/blst_mul_mont_384_rvv.o: build/blst_mul_mont_384_rvv_gen.S
	$(CC) -c -DCKB_DECLARATION_ONLY $(CFLAGS_BLST) -o $@ $^

build/blst_mul_mont_384x.o: blst/blst_mul_mont_384x.riscv.S
	$(CC) -c -DCKB_DECLARATION_ONLY $(CFLAGS_BLST) -o $@ $^

build/blst-demo-no-asm: tests/blst/main.c build/server.o
	$(CC) $(CFLAGS_BLST) ${LDFLAGS} -o $@ $^

build/blst-demo: tests/blst/main.c build/server-asm.o build/blst_mul_mont_384.o build/blst_mul_mont_384x.o
	$(CC) $(CFLAGS_BLST) ${LDFLAGS} -o $@ $^

build/blst-demo-rvv: tests/blst/main.c build/server-asm-rvv.o build/blst_mul_mont_384_rvv.o build/blst_mul_mont_384x.o
	$(CC) $(CFLAGS_BLST) ${LDFLAGS} -o $@ $^

run-blst-no-asm: build/blst-demo-no-asm
	$(CKB_VM_CLI) --bin build/blst-demo-no-asm

run-blst: build/blst-demo
	$(CKB_VM_CLI) --bin build/blst-demo

run-blst-rvv: build/blst-demo-rvv
	$(CKB_VM_CLI) --bin build/blst-demo-rvv

install-ckb-vm-cli:
	echo "start to install tool: ckb-vm-cli"
	cargo install --git https://github.com/XuJiandong/ckb-vm-cli.git --branch b-extension

rc_lock_mol:
	${MOLC} --language rust --schema-file c/rc_lock.mol | rustfmt > tests/blst_rust/src/rc_lock.rs
	${MOLC} --language c --schema-file c/rc_lock.mol > c/rc_lock_mol.h
	${MOLC} --language - --schema-file c/rc_lock.mol --format json > build/rc_lock_mol2.json
	moleculec-c2 --input build/rc_lock_mol2.json | clang-format -style=Google > c/rc_lock_mol2.h


fmt:
	clang-format -i -style=Google $(wildcard c/*.h c/*.c)
	git diff --exit-code $(wildcard c/*.h c/*.c)

clean:
	rm -rf build/htlc build/dump_secp256k1_data build/secp256k1_data build/secp256k1_data_info.h
	rm -rf build/generate_data_hash build/secp256k1_blake2b_sighash_all_lib.h
	rm -rf build/secp256k1_blake2b_sighash_all_lib.so
	rm -rf build/*.debug
	rm -rf build/or
	rm -rf build/simple_udt build/secp256k1_blake2b_sighash_all_dual build/and
	cd deps/secp256k1 && [ -f "Makefile" ] && make clean
	make -C deps/mbedtls/library clean
	rm -f build/rsa_sighash_all
	rm -f build/blst* build/server.o build/server-asm.o build/server-asm-rvv.o

dist: clean all

.PHONY: all all-via-docker dist clean fmt
