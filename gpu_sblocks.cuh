#ifndef GPUSBLOCK
#define GPUSBLOCK
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <stdint.h>

typedef uint64_t block_t;

__device__ block_t gpu_sfun(block_t block);

#endif
