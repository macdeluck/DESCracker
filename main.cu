#include <cstdlib>
#include <cstdio>
#include <cstring>
#include <cstdint>
#include <ctime>
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
	
	memset(msg, 0, sizeof(msg));
	text_to_block("bcc", msg);
	text_to_block("bcc", &key);

	printf("Key: %016llx\n", key);
	des_encrypt(msg, MSG_LEN, key);
	for (int i = 0; i < MSG_LEN; i++)
		printf("%016llx ", msg[i]);
	printf("\n");
	
	clock_t started, finished;

	started = clock();
	cracked_key = gpu_des_crack(msg[0]);
	finished = clock();
	printf("\nCracked key: %016llx \n", cracked_key);
	int millis = ((finished - started) * 1000) / CLOCKS_PER_SEC;
	int sec = millis / 1000;
	int min = sec / 60;
	int h = min / 60;
	printf("Calculations time: %02d:%02d:%02d:%03d\n", h, min%60, sec%60, millis%1000);

	system("pause");
	return 0;
}