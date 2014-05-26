#ifndef GPUDESCRACKER
#define GPUDESCRACKER
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include "gpu_descommon.cuh"

block_t gpu_des_crack(block_t msg);

#endif