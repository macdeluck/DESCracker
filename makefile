OUTPUT=DESCracker
compile: gpu_descommon.o gpu_descracker.o gpu_sblocks.o descommon.o descracker.o sblocks.o main.o
	nvcc -o ${OUTPUT} descommon.o descracker.o sblocks.o main.o

descommon.o: descommon.cpp
	nvcc -c -o descommon.o descommon.cpp	
	
descracker.o: descracker.cpp
	nvcc -c -o descracker.o descracker.cpp
	
sblocks.o: sblocks.cpp
	nvcc -c -o sblocks.o sblocks.cpp
	
main.o: main.cpp
	nvcc -c -o main.o main.cpp
	
gpu_descommon.o: GPU/gpu_descommon.cpp
	nvcc -c -o gpu_descommon.o GPU/gpu_descommon.cpp	
	
gpu_descracker.o: GPU/gpu_descracker.cpp
	nvcc -c -o gpu_descracker.o GPU/gpu_descracker.cpp
	
gpu_sblocks.o: GPU/gpu_sblocks.cpp
	nvcc -c -o gpu_sblocks.o GPU/gpu_sblocks.cpp