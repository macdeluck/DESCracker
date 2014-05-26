OUTPUT=DESCracker
CFLAGS=-std=c++11
compile: gpu_descommon.o gpu_descracker.o gpu_sblocks.o descommon.o descracker.o sblocks.o main.o
	nvcc -o ${OUTPUT} descommon.o descracker.o sblocks.o main.o

descommon.o: descommon.cpp
	nvcc -c ${CFLAGS} -o descommon.o descommon.cpp	
	
descracker.o: descracker.cpp
	nvcc -c ${CFLAGS} -o descracker.o descracker.cpp
	
sblocks.o: sblocks.cpp
	nvcc -c ${CFLAGS} -o sblocks.o sblocks.cpp
	
main.o: main.cu
	nvcc -c ${CFLAGS} -o main.o main.cu
	
gpu_descommon.o: gpu_descommon.cu
	nvcc -c ${CFLAGS} -o gpu_descommon.o gpu_descommon.cu	
	
gpu_descracker.o: gpu_descracker.cu
	nvcc -c ${CFLAGS} -o gpu_descracker.o GPU/gpu_descracker.cu
	
gpu_sblocks.o: gpu_sblocks.cu
	nvcc -c ${CFLAGS} -o gpu_sblocks.o gpu_sblocks.cu
