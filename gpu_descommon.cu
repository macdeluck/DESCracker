#include "gpu_descommon.cuh"
#include "gpu_sblocks.cuh"
#include <stdio.h>
#include <string.h>

__constant__ char gpu_pc1[] = //first key permutation
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

__constant__ char gpu_pc2[] = //second key premutation
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

__constant__ char gpu_key_shift_table[] =
{
	1, 1, 2, 2, 2, 2, 2, 2, 1, 2, 2, 2, 2, 2, 2, 1
};

__constant__ char gpu_ip[] = //initial permutation
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

__constant__ char gpu_ipr[] = //final permutation
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

__constant__ char gpu_st[] = //selection table
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

__constant__ char gpu_P[] = //ffun permutation table
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

__device__ block_t gpu_get_first_message_part(block_t block);
__device__ block_t gpu_get_second_message_part(block_t block);
__device__ block_t gpu_permute_message_block(block_t m, const char* pctable, int len=64);
__device__ block_t gpu_permute_key(block_t m, const char* pctable);
__device__ block_t gpu_get_first_key_part(block_t permutedKey);
__device__ block_t gpu_get_second_key_part(block_t permutedKey);
__device__ block_t gpu_shift_rigth_key_part(block_t k, int num);
__device__ block_t gpu_expand_block(block_t block, const char* seltable);
__device__ block_t gpu_ffunpart(block_t key, block_t r);

__device__ int gpu_strlen(const char* string)
{
	int i=0;
	while(string[i]) i++;
	return i;
}

__device__ block_t gpu_permute_key(block_t m, const char* pctable)
{
	uint64_t outblock = 0;
	int shift = 0;
	uint64_t j, b;
	for (j = 0; j < 64; j++)
	{
		if (j % 8 != 7)
		{
			b = (m >> (pctable[j - shift] - 1)) & 1; // -1 because we number from 0
			GPUSETBYTE(&outblock, 0, j - shift, b);
		}
		else shift++;
	}
	return outblock;
}

__device__ block_t gpu_get_first_key_part(block_t k)
{
	return k & 0xfffffff;
}

__device__ block_t gpu_get_second_key_part(block_t k)
{
	return (k & ((block_t)0xfffffff) << 28) >> 28;
}

__device__ block_t gpu_get_first_message_part(block_t k)
{
	return k & 0xffffffff;
}

__device__ block_t gpu_get_second_message_part(block_t k)
{
	return (k & ((block_t)0xffffffff) << 32) >> 32;
}

__device__ block_t gpu_shift_rigth_key_part(block_t k, int num)
{
	k = k | k << 28;
	k = k >> num & 0xfffffff;
	return k;
}

__device__ void gpu_generate_keys(block_t key, block_t* k)
{
	block_t c[17], d[17];
	int i;

	key = gpu_permute_key(key, gpu_pc1);

	c[0] = gpu_get_first_message_part(key);
	d[0] = gpu_get_second_key_part(key);
	for (i = 1; i < 17; i++)
	{
		c[i] = gpu_shift_rigth_key_part(c[i - 1], gpu_key_shift_table[i - 1]);
		d[i] = gpu_shift_rigth_key_part(d[i - 1], gpu_key_shift_table[i - 1]);
		k[i] = (d[i] << 28) | c[i];
		k[i] = gpu_permute_key(k[i], gpu_pc2) & 0xffffffffffff;
	}
}


__device__ block_t gpu_permute_message_block(block_t m, const char* pctable, int len)
{
	uint64_t outblock = 0;
	uint64_t j, b;
	for (j = 0; j < len; j++)
	{
		b = (m >> (pctable[j] - 1)) & 1; // -1 because we number from 0
		GPUSETBYTE(&outblock, 0, j, b);
	}
	return outblock;
}

__device__ void gpu_permute_message(block_t* m, int count, const char* pctable)
{
	int i;
	for (i = 0; i < count; i++)
	{
		m[i] = gpu_permute_message_block(m[i], pctable);
	}
}

__device__ block_t gpu_ffunpart(block_t key, block_t r)
{
	block_t ret;
	ret = gpu_permute_message_block(r, gpu_st);
	ret = key ^ (ret);
	ret = gpu_sfun(ret);
	ret = gpu_permute_message_block(ret, gpu_P, 32);
	return ret;
}

__device__ block_t gpu_ffun(block_t msg, block_t* k)
{
	block_t l[18], r[18];
	int i;
	msg = gpu_permute_message_block(msg, gpu_ip);
	l[0] = gpu_get_first_message_part(msg);
	r[0] = gpu_get_second_message_part(msg);
	for (i = 0; i < 17; i++)
	{
		r[i+1] = l[i] ^ gpu_ffunpart(k[i + 1], r[i]);
		l[i + 1] = r[i];
	}
	msg = r[16] | (l[16] << 32);
	msg = gpu_permute_message_block(msg, gpu_ipr);
	return msg;
}

__constant__ uint8_t gpu_lookup[16] = 
{
	0x0, 0x8, 0x4, 0xC,
	0x2, 0xA, 0x6, 0xE,
	0x1, 0x9, 0x5, 0xD,
	0x3, 0xB, 0x7, 0xF 
};

__device__ uint8_t gpu_flip8(uint8_t n)
{
	return (gpu_lookup[n & 0x0F] << 4) | gpu_lookup[n >> 4];
}

__device__ uint16_t gpu_flip16(uint16_t n)
{
	return gpu_flip8((uint8_t)((n >> 8) & 0xff)) | (gpu_flip8((uint8_t)(n & 0xff))<<8);
}

__device__ uint32_t gpu_flip32(uint32_t n)
{
	return gpu_flip16((uint16_t)((n >> 16) & 0xffff)) | (gpu_flip16((uint16_t)(n & 0xffff)) << 16);
}

__device__ uint64_t gpu_flip64(uint64_t n)
{
	return gpu_flip32((uint32_t)((n >> 32) & 0xffffffff)) | (((uint64_t)gpu_flip32((uint32_t)(n & 0xffffffff))) << 32);
}

__device__ void gpu_flip(block_t* message, int length)
{
	int i;
	for (i = 0; i < length; i++)
		message[i] = gpu_flip64(message[i]);
}

__device__ void gpu_des_encrypt(block_t* msg, int len, block_t key)
{
	block_t k[17];
	int i;
	gpu_flip(msg, len);
	key = gpu_flip64(key);

	gpu_generate_keys(key, k);
	for (i = 0; i < len; i++)
		msg[i] = gpu_ffun(msg[i], k);

	gpu_flip(msg, len);
}

__device__ void gpu_text_to_block(const char* message, block_t* output)
{
	int length = gpu_strlen(message);
	int cnt = length / 8 + ((length % 8) != 0);
	int i, j;
	for (i = 0; i < cnt; i ++)
	{
		output[i] = 0;
		for (j = 0; (j < 8) && i*8+j<length; j++)
		{
			((char*)output)[i * 8 + 7 - j] = message[j + i * 8];
		}
	}
}
