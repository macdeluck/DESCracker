#ifndef GPUDESCOMMON
#define GPUDESCOMMON
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <stdint.h>

typedef uint64_t block_t;

#define GPUSETBYTE(msg, block, bitnum, value)\
{(msg)[0] = ((msg)[0] & ~(((block_t)1) << (bitnum))) | ((block_t)((value) != 0)) << (bitnum);}

__device__ void gpu_permute_message(block_t* m, int count, const char* pctable);
__device__ void gpu_generate_keys(block_t key, block_t* k);
__device__ block_t gpu_ffun(block_t block, block_t* keys);

__device__ void gpu_des_encrypt(block_t* msg, int len, block_t key);

__device__ uint64_t flip64(uint64_t n);
__device__ uint32_t flip32(uint32_t n);
__device__ uint16_t flip16(uint16_t n);
__device__ uint8_t flip8(uint8_t n);
__device__ void flip(block_t* message, int length);

__device__ void text_to_block(const char* message, block_t* output);
#endif
