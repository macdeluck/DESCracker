#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <time.h>
#include "descommon.h"
#include "descracker.h"
#include "gpu_descracker.cuh"
#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#define MSG_LEN 1

int main(int argc, char** argv)
{
	block_t key;
	block_t msg[MSG_LEN];
	block_t cracked_key;
	int i;
	clock_t started, finished;
	int millis, sec, min, h;
	
	memset(msg, 0, sizeof(msg));
	text_to_block("bcc", msg);
	text_to_block("bcc", &key);

	printf("Key: %016lx\n", key);
	des_encrypt(msg, MSG_LEN, key);
	for (i = 0; i < MSG_LEN; i++)
		printf("%016lx ", msg[i]);
	printf("\n");

	started = clock();
	cracked_key = gpu_des_crack(msg[0]);
	finished = clock();
	printf("\nCracked key: %016lx \n", cracked_key);
	millis = ((finished - started) * 1000) / CLOCKS_PER_SEC;
	sec = millis / 1000;
	min = sec / 60;
	h = min / 60;
	printf("Calculations time: %02d:%02d:%02d:%03d\n", h, min%60, sec%60, millis%1000);

	system("pause");
	return 0;
}
