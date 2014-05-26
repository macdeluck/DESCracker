#include "descommon.h"
#include "sblocks.h"
#include <stdio.h>
#include <string.h>

const char pc1[] = //first key permutation
{
	57, 49, 41, 33, 25, 17, 9,
	1, 58, 50, 42, 34, 26, 18,
	10, 2, 59, 51, 43, 35, 27,
	19, 11, 3, 60, 52, 44, 36,
	63, 55, 47, 39, 31, 23, 15,
	7, 62, 54, 46, 38, 30, 22,
	14, 6, 61, 53, 45, 37, 29,
	21, 13, 5, 28, 20, 12, 4
};

const char pc2[] = //second key premutation
{
	14, 17, 11, 24, 1, 5,
	3, 28, 15, 6, 21, 10,
	23, 19, 12, 4, 26, 8,
	16, 7, 27, 20, 13, 2,
	41, 52, 31, 37, 47, 55,
	30, 40, 51, 45, 33, 48,
	44, 49, 39, 56, 34, 53,
	46, 42, 50, 36, 29, 32
};

const char key_shift_table[] =
{
	1, 1, 2, 2, 2, 2, 2, 2, 1, 2, 2, 2, 2, 2, 2, 1
};

const char ip[] = //initial permutation
{
	58, 50, 42, 34, 26, 18, 10, 2,
	60, 52, 44, 36, 28, 20, 12, 4,
	62, 54, 46, 38, 30, 22, 14, 6,
	64, 56, 48, 40, 32, 24, 16, 8,
	57, 49, 41, 33, 25, 17, 9, 1,
	59, 51, 43, 35, 27, 19, 11, 3,
	61, 53, 45, 37, 29, 21, 13, 5,
	63, 55, 47, 39, 31, 23, 15, 7
};

const char ipr[] = //final permutation
{
	40,     8,   48,    16,    56,   24,    64,   32,
	39,     7,   47,    15,    55,   23,    63,   31,
	38,     6,   46,    14,    54,   22,    62,   30,
	37,     5,   45,    13,    53,   21,    61,   29,
	36,     4,   44,    12,    52,   20,    60,   28,
	35,     3,   43,    11,    51,   19,    59,   27,
	34,     2,   42,    10,    50,   18,    58,   26,
	33,     1,   41,     9,    49,   17,    57,   25
};

const char st[] = //selection table
{
	32, 1, 2, 3, 4, 5,
	4, 5, 6, 7, 8, 9,
	8, 9, 10, 11, 12, 13,
	12, 13, 14, 15, 16, 17,
	16, 17, 18, 19, 20, 21,
	20, 21, 22, 23, 24, 25,
	24, 25, 26, 27, 28, 29,
	28, 29, 30, 31, 32, 1
};

const char P[] = //ffun permutation table
{
	16,   7,  20,  21,
	29,  12,  28,  17,
	 1,  15,  23,  26,
	 5,  18,  31,  10,
	 2,   8,  24,  14,
	32,  27,   3,   9,
	19,  13,  30,   6,
	22,  11,   4,  25
};

block_t get_first_message_part(block_t block);
block_t get_second_message_part(block_t block);
block_t permute_message_block(block_t m, const char* pctable, int len);
block_t permute_key(block_t m, const char* pctable);
block_t get_first_key_part(block_t permutedKey);
block_t get_second_key_part(block_t permutedKey);
block_t shift_rigth_key_part(block_t k, int num);
block_t expand_block(block_t block, const char* seltable);
block_t ffunpart(block_t key, block_t r);

block_t permute_key(block_t m, const char* pctable)
{
	uint64_t outblock = 0;
	uint64_t j, b;
	int shift = 0;
	for (j = 0; j < 64; j++)
	{
		if (j % 8 != 7)
		{
			b = (m >> (pctable[j - shift] - 1)) & 1; // -1 because we number from 0
			SETBYTE(&outblock, 0, j - shift, b);
		}
		else shift++;
	}
	return outblock;
}

void write_block_bytes(block_t m)
{
	int i;
	// byte 0 is the least significant
	for (i = 0; i < 64; i++)
	{
		if (!(i % 16))
			printf("\n");
		if (!(i % 4))
			printf("%2d: ", i);
		printf("%lx ", (m >> i) & 1);
	}
	printf("\n");
}

block_t get_first_key_part(block_t k)
{
	return k & 0xfffffff;
}

block_t get_second_key_part(block_t k)
{
	return (k & ((block_t)0xfffffff) << 28) >> 28;
}

block_t get_first_message_part(block_t k)
{
	return k & 0xffffffff;
}

block_t get_second_message_part(block_t k)
{
	return (k & ((block_t)0xffffffff) << 32) >> 32;
}

block_t shift_rigth_key_part(block_t k, int num)
{
	k = k | k << 28;
	k = k >> num & 0xfffffff;
	return k;
}

void generate_keys(block_t key, block_t* k)
{
	block_t c[17], d[17];
	int i;

	key = permute_key(key, pc1);

	c[0] = get_first_key_part(key);
	d[0] = get_second_key_part(key);
	for (i = 1; i < 17; i++)
	{
		c[i] = shift_rigth_key_part(c[i - 1], key_shift_table[i - 1]);
		d[i] = shift_rigth_key_part(d[i - 1], key_shift_table[i - 1]);
		k[i] = (d[i] << 28) | c[i];
		k[i] = permute_key(k[i], pc2) & 0xffffffffffff;
	}
}


block_t permute_message_block(block_t m, const char* pctable, int len)
{
	uint64_t outblock = 0;
	uint64_t j, b;
	for (j = 0; j < len; j++)
	{
		b = (m >> (pctable[j] - 1)) & 1; // -1 because we number from 0
		SETBYTE(&outblock, 0, j, b);
	}
	return outblock;
}

void permute_message(block_t* m, int count, const char* pctable)
{
	int i;
	for (i = 0; i < count; i++)
	{
		m[i] = permute_message_block(m[i], pctable, 64);
	}
}

block_t ffunpart(block_t key, block_t r)
{
	block_t ret;
	ret = permute_message_block(r, st, 64);
	ret = key ^ (ret);
	ret = sfun(ret);
	ret = permute_message_block(ret, P, 32);
	return ret;
}

block_t ffun(block_t msg, block_t* k)
{
	block_t l[18], r[18];
	int i;
	msg = permute_message_block(msg, ip, 64);
	l[0] = get_first_message_part(msg);
	r[0] = get_second_message_part(msg);
	for (i = 0; i < 17; i++)
	{
		r[i+1] = l[i] ^ ffunpart(k[i + 1], r[i]);
		l[i + 1] = r[i];
	}
	msg = r[16] | (l[16] << 32);
	msg = permute_message_block(msg, ipr, 64);
	return msg;
}

uint8_t lookup[16] = 
{
	0x0, 0x8, 0x4, 0xC,
	0x2, 0xA, 0x6, 0xE,
	0x1, 0x9, 0x5, 0xD,
	0x3, 0xB, 0x7, 0xF 
};

uint8_t flip8(uint8_t n)
{
	return (lookup[n & 0x0F] << 4) | lookup[n >> 4];
}

uint16_t flip16(uint16_t n)
{
	return flip8((uint8_t)((n >> 8) & 0xff)) | (flip8((uint8_t)(n & 0xff))<<8);
}

uint32_t flip32(uint32_t n)
{
	return flip16((uint16_t)((n >> 16) & 0xffff)) | (flip16((uint16_t)(n & 0xffff)) << 16);
}

uint64_t flip64(uint64_t n)
{
	return flip32((uint32_t)((n >> 32) & 0xffffffff)) | (((uint64_t)flip32((uint32_t)(n & 0xffffffff))) << 32);
}

void flip(block_t* message, int length)
{
	int i;
	for (i = 0; i < length; i++)
		message[i] = flip64(message[i]);
}

void des_encrypt(block_t* msg, int len, block_t key)
{
	block_t k[17];
	int i;
	flip(msg, len);
	key = flip64(key);

	generate_keys(key, k);
	for (i = 0; i < len; i++)
		msg[i] = ffun(msg[i], k);

	flip(msg, len);
}

void text_to_block(const char* message, block_t* output)
{
	int i, j;
	int length = strlen(message);
	int cnt = length / 8 + ((length % 8) != 0);
	for (i = 0; i < cnt; i ++)
	{
		output[i] = 0;
		for (j = 0; (j < 8) && i*8+j<length; j++)
		{
			((char*)output)[i * 8 + 7 - j] = message[j + i * 8];
		}
	}
}
