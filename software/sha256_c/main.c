#include <stdio.h>
#include <string.h>
#include "sha256.h"

static void print_hash(const uint8_t hash[32]) {
    for (int i = 0; i < 32; i++) {
        printf("%02x", hash[i]);
    }
    printf("\n");
}

int main(void) {
    SHA256_CTX ctx;
    uint8_t hash[32];
    int pass = 1;

    // Test 1: "abc"
    // ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad
    const uint8_t exp1[32] = {
        0xba, 0x78, 0x16, 0xbf, 0x8f, 0x01, 0xcf, 0xea,
        0x41, 0x41, 0x40, 0xde, 0x5d, 0xae, 0x22, 0x23,
        0xb0, 0x03, 0x61, 0xa3, 0x96, 0x17, 0x7a, 0x9c,
        0xb4, 0x10, 0xff, 0x61, 0xf2, 0x00, 0x15, 0xad
    };
    const char *str1 = "abc";
    sha256_init(&ctx);
    sha256_update(&ctx, (const uint8_t *)str1, strlen(str1));
    sha256_final(&ctx, hash);

    printf("Test 1 ('abc'):\n  Got:      ");
    print_hash(hash);
    printf("  Expected: ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad\n");
    if (memcmp(hash, exp1, 32) != 0) {
        printf("  FAIL!\n");
        pass = 0;
    } else {
        printf("  PASS!\n");
    }

    // Test 2: ""
    // e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
    const uint8_t exp2[32] = {
        0xe3, 0xb0, 0xc4, 0x42, 0x98, 0xfc, 0x1c, 0x14,
        0x9a, 0xfb, 0xf4, 0xc8, 0x99, 0x6f, 0xb9, 0x24,
        0x27, 0xae, 0x41, 0xe4, 0x64, 0x9b, 0x93, 0x4c,
        0xa4, 0x95, 0x99, 0x1b, 0x78, 0x52, 0xb8, 0x55
    };
    sha256_init(&ctx);
    sha256_update(&ctx, (const uint8_t *)"", 0);
    sha256_final(&ctx, hash);

    printf("Test 2 (empty):\n  Got:      ");
    print_hash(hash);
    printf("  Expected: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\n");
    if (memcmp(hash, exp2, 32) != 0) {
        printf("  FAIL!\n");
        pass = 0;
    } else {
        printf("  PASS!\n");
    }

    // Test 3: "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq" (two blocks)
    // 248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1
    const uint8_t exp3[32] = {
        0x24, 0x8d, 0x6a, 0x61, 0xd2, 0x06, 0x38, 0xb8,
        0xe5, 0xc0, 0x26, 0x93, 0x0c, 0x3e, 0x60, 0x39,
        0xa3, 0x3c, 0xe4, 0x59, 0x64, 0xff, 0x21, 0x67,
        0xf6, 0xec, 0xed, 0xd4, 0x19, 0xdb, 0x06, 0xc1
    };
    const char *str3 = "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq";
    sha256_init(&ctx);
    sha256_update(&ctx, (const uint8_t *)str3, strlen(str3));
    sha256_final(&ctx, hash);

    printf("Test 3 (multi-block):\n  Got:      ");
    print_hash(hash);
    printf("  Expected: 248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1\n");
    if (memcmp(hash, exp3, 32) != 0) {
        printf("  FAIL!\n");
        pass = 0;
    } else {
        printf("  PASS!\n");
    }

    if (pass) {
        printf("ALL SOFTWARE C SHA-256 TESTS PASSED!\n");
        return 0;
    } else {
        printf("SOME TESTS FAILED!\n");
        return 1;
    }
}

