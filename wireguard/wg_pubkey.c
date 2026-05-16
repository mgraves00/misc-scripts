#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <sodium.h> // Requires libsodium

// Base64 character set
static const char b64_chars[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

// Helper to find the index of a base64 character
static int b64_inv(char c) {
    if (c >= 'A' && c <= 'Z') return c - 'A';
    if (c >= 'a' && c <= 'z') return c - 'a' + 26;
    if (c >= '0' && c <= '9') return c - '0' + 52;
    if (c == '+') return 62;
    if (c == '/') return 63;
    return -1;
}

// Decodes a Base64 string into a 32-byte array
int base64_decode(const char *in, uint8_t *out, size_t out_len) {
    size_t in_len = strlen(in);
    if (in_len % 4 != 0 || out_len < 32) return 0;

    size_t i, j;
    for (i = 0, j = 0; i < in_len; i += 4) {
        int v1 = b64_inv(in[i]);
        int v2 = b64_inv(in[i+1]);
        int v3 = in[i+2] == '=' ? 0 : b64_inv(in[i+2]);
        int v4 = in[i+3] == '=' ? 0 : b64_inv(in[i+3]);

        if (v1 < 0 || v2 < 0 || v3 < 0 || v4 < 0) return 0;

        out[j++] = (v1 << 2) | (v2 >> 4);
        if (in[i+2] != '=') out[j++] = ((v2 & 0xF) << 4) | (v3 >> 2);
        if (in[i+3] != '=') out[j++] = ((v3 & 0x3) << 6) | v4;
    }
    return 1;
}

// Encodes a 32-byte array into a Base64 string
void base64_encode(const uint8_t *in, size_t in_len, char *out) {
    size_t i, j;
    for (i = 0, j = 0; i < in_len; i += 3) {
        uint32_t v = in[i] << 16;
        if (i + 1 < in_len) v |= in[i+1] << 8;
        if (i + 2 < in_len) v |= in[i+2];

        out[j++] = b64_chars[(v >> 18) & 0x3F];
        out[j++] = b64_chars[(v >> 12) & 0x3F];
        out[j++] = (i + 1 < in_len) ? b64_chars[(v >> 6) & 0x3F] : '=';
        out[j++] = (i + 2 < in_len) ? b64_chars[v & 0x3F] : '=';
    }
    out[j] = '\0';
}

int main() {
    // Initialize libsodium
    if (sodium_init() < 0) {
        fprintf(stderr, "Error: libsodium initialization failed.\n");
        return 1;
    }

    char input_priv_b64[64];
    uint8_t raw_priv_key[32];
    uint8_t raw_pub_key[32];
    char output_pub_b64[45];

    printf("Enter WireGuard Base64 Private Key: ");
    if (scanf("%63s", input_priv_b64) != 1) {
        fprintf(stderr, "Error reading input.\n");
        return 1;
    }

    input_priv_b64[strcspn(input_priv_b64, "\r\n")] = 0;

    // 1. Decode Base64 Private Key to 32-byte Binary
    if (!base64_decode(input_priv_b64, raw_priv_key, sizeof(raw_priv_key))) {
        fprintf(stderr, "Error: Invalid Base64 input or incorrect key length.\n");
        return 1;
    }

    // 2. Generate Public Key from Private Key using Curve25519
    // crypto_scalarmult_base computes the public key from a given private key
    if (crypto_scalarmult_base(raw_pub_key, raw_priv_key) != 0) {
        fprintf(stderr, "Error: Failed to derive public key.\n");
        return 1;
    }

    // 3. Encode the 32-byte Public Key back to Base64
    base64_encode(raw_pub_key, sizeof(raw_pub_key), output_pub_b64);

    // 4. Output the result
    printf("Derived WireGuard Base64 Public Key: %s\n", output_pub_b64);

    return 0;
}
