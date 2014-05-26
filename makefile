OUTPUT=DESCracker
CFLAGS=
compile: gpu_descommon.o gpu_descracker.o gpu_sblocks.o descommon.o descracker.o sblocks.o main.o
	nvcc -o ${OUTPUT} descommon.o descracker.o sblocks.o main.o

descommon.o: descommon.c
	nvcc -c ${CFLAGS} -o descommon.o descommon.c
	
descracker.o: descracker.c
	nvcc -c ${CFLAGS} -o descracker.o descracker.c
	
sblocks.o: sblocks.c
	nvcc -c ${CFLAGS} -o sblocks.o sblocks.c
	
main.o: main.cu
	nvcc -c ${CFLAGS} -o main.o main.cu
	
gpu_descommon.o: gpu_descommon.cu
	nvcc -c ${CFLAGS} -o gpu_descommon.o gpu_descommon.cu	
	
gpu_descracker.o: gpu_descracker.cu
	nvcc -c ${CFLAGS} -o gpu_descracker.o gpu_descracker.cu
	
gpu_sblocks.o: gpu_sblocks.cu
	nvcc -c ${CFLAGS} -o gpu_sblocks.o gpu_sblocks.cu
