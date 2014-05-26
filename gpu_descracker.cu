#include "gpu_descracker.cuh"
#include <cstring>
#include <cstdio>

#define BLOCKSIZE 60

__device__ char gpu_alphabet[] = { 0, 'a', 'b', 'c'};

__device__ void gpu_word_for(int num, block_t* word, int alphabets)
{
	int sub = 1;
	int exp = 1;

	alphabets--;
	((char*)word)[7] = gpu_alphabet[((num - sub) >= 0)*(((num - sub) / exp) % alphabets + 1)];
	exp *= alphabets;
	sub += exp;
	((char*)word)[6] = gpu_alphabet[((num - sub) >= 0)*(((num - sub) / exp) % alphabets + 1)];
	exp *= alphabets;
	sub += exp;
	((char*)word)[5] = gpu_alphabet[((num - sub) >= 0)*(((num - sub) / exp) % alphabets + 1)];
	exp *= alphabets;
	sub += exp;
	((char*)word)[4] = gpu_alphabet[((num - sub) >= 0)*(((num - sub) / exp) % alphabets + 1)];
	exp *= alphabets;
	sub += exp;
	((char*)word)[3] = gpu_alphabet[((num - sub) >= 0)*(((num - sub) / exp) % alphabets + 1)];
	exp *= alphabets;
	sub += exp;
	((char*)word)[2] = gpu_alphabet[((num - sub) >= 0)*(((num - sub) / exp) % alphabets + 1)];
	exp *= alphabets;
	sub += exp;
	((char*)word)[1] = gpu_alphabet[((num - sub) >= 0)*(((num - sub) / exp) % alphabets + 1)];
	exp *= alphabets;
	sub += exp;
	((char*)word)[0] = gpu_alphabet[((num - sub) >= 0)*(((num - sub) / exp) % alphabets + 1)];
}

__host__ __device__ void gpu_fast_text_to_block(const char* text, block_t* block)
{
	*block = (0x00ffffffffffffff & *block) | (((block_t)(text[0])) << 56);
	*block = (0xff00ffffffffffff & *block) | (((block_t)(text[1])) << 48);
	*block = (0xffff00ffffffffff & *block) | (((block_t)(text[2])) << 40);
	*block = (0xffffff00ffffffff & *block) | (((block_t)(text[3])) << 32);
	*block = (0xffffffff00ffffff & *block) | (((block_t)(text[4])) << 24);
	*block = (0xffffffffff00ffff & *block) | (((block_t)(text[5])) << 16);
	*block = (0xffffffffffff00ff & *block) | (((block_t)(text[6])) << 8);
	*block = (0xffffffffffffff00 & *block) | ((block_t)(text[7]));
}

__global__ void gpu_des_crack_kernel(block_t* msg, block_t* lastWord, int keyshift, int* valid, block_t* keys)
{
	int keynum = blockDim.x*blockIdx.x + threadIdx.x;
	int val = 0;
	block_t tmpmsg, tmpkey, wordnum, encmsg; 
	gpu_word_for(keynum, &keys[keynum], 4);
	/*tmpmsg = 0;
	wordnum = 0;
	while (tmpmsg != *lastWord)
	{
		gpu_word_for(wordnum++, &tmpmsg, 4);

		encmsg = tmpmsg;
		gpu_des_encrypt(&encmsg, 1, tmpkey);
		if (encmsg == *msg)
			val = 1;
	}*/
	valid[keynum] = val;
}

block_t gpu_des_crack(block_t msg)
{
    cudaError_t cudaStatus;
	block_t lastWord;
	int alphabets = sizeof(gpu_alphabet);
	int *dev_valid;
	block_t *dev_keys, *dev_message, *dev_lastWord;
	char mess[9];
	block_t keys[BLOCKSIZE];
	int valid[BLOCKSIZE];
	
	cudaStatus = cudaSetDevice(0);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaSetDevice failed!  Do you have a CUDA-capable GPU installed?");
		return 0;
    }

	cudaStatus = cudaMalloc((void**)&dev_keys, BLOCKSIZE * sizeof(block_t));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
        return 0;
    }

	cudaStatus = cudaMalloc((void**)&dev_valid, BLOCKSIZE * sizeof(int));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
		cudaFree(dev_keys);
        return 0;
    }

	cudaStatus = cudaMalloc((void**)&dev_lastWord, sizeof(block_t));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
		cudaFree(dev_keys);
		cudaFree(dev_valid);
        return 0;
    }

	cudaStatus = cudaMalloc((void**)&dev_message, sizeof(block_t));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
		cudaFree(dev_keys);
		cudaFree(dev_valid);
		cudaFree(dev_lastWord);
        return 0;
    }

	cudaStatus = cudaMemcpy(dev_lastWord, &lastWord, sizeof(block_t), cudaMemcpyHostToDevice);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    }

	cudaStatus = cudaMemcpy(dev_message, &msg, sizeof(block_t), cudaMemcpyHostToDevice);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    }

	memset(mess, 0, 9);
	memset(mess, 'c', 8);
	gpu_fast_text_to_block(mess, &lastWord);

	gpu_des_crack_kernel<<<1, BLOCKSIZE>>>(dev_message, dev_lastWord, 0, dev_valid, dev_keys);

    cudaStatus = cudaDeviceSynchronize();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaDeviceSynchronize returned error code %d after launching addKernel!\n", cudaStatus);
        goto Error;
    }

	cudaStatus = cudaMemcpy(keys, dev_keys, BLOCKSIZE * sizeof(block_t), cudaMemcpyDeviceToHost);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy keys failed!");
        goto Error;
    }
	cudaStatus = cudaMemcpy(valid, dev_valid, BLOCKSIZE * sizeof(int), cudaMemcpyDeviceToHost);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy valid failed!");
        goto Error;
    }

	for(int i=0; i<BLOCKSIZE; i++)
		printf("%d, %016llx\n", valid[i], keys[i]);

Error:
	cudaFree(dev_keys);
	cudaFree(dev_valid);
	cudaFree(dev_lastWord);
	cudaFree(dev_message);
	return 0;
}