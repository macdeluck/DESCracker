#ifndef DESCOMMON
#define DESCOMMON

#include <stdint.h>

typedef uint64_t block_t;

#define SETBYTE(msg, block, bitnum, value)\
{(msg)[0] = ((msg)[0] & ~(((block_t)1) << (bitnum))) | ((block_t)((value) != 0)) << (bitnum);}

void permute_message(block_t* m, int count, const char* pctable);
void generate_keys(block_t key, block_t* k);
void write_block_bytes(block_t message);
block_t ffun(block_t block, block_t* keys);

void des_encrypt(block_t* msg, int len, block_t key);

uint64_t flip64(uint64_t n);
uint32_t flip32(uint32_t n);
uint16_t flip16(uint16_t n);
uint8_t flip8(uint8_t n);
void flip(block_t* message, int length);

void text_to_block(const char* message, block_t* output);
#endif
