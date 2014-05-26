OUTPUT=DESCracker
compile: gpu_descommon.o gpu_descracker.o gpu_sblocks.o descommon.o descracker.o sblocks.o main.o
	nvcc -o ${OUTPUT} descommon.o descracker.o sblocks.o main.o

descommon.o: descommon.cpp
	nvcc -c -o descommon.o descommon.cpp	
	
descracker.o: descracker.cpp
	nvcc -c -o descracker.o descracker.cpp
	
sblocks.o: sblocks.cpp
	nvcc -c -o sblocks.o sblocks.cpp
	
main.o: main.cu
	nvcc -c -o main.o main.cu
	
gpu_descommon.o: gpu_descommon.cu
	nvcc -c -o gpu_descommon.o gpu_descommon.cu	
	
gpu_descracker.o: gpu_descracker.cu
	nvcc -c -o gpu_descracker.o GPU/gpu_descracker.cu
	
gpu_sblocks.o: gpu_sblocks.cu
	nvcc -c -o gpu_sblocks.o gpu_sblocks.cu
