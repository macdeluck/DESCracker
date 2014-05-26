OUTPUT=DESCracker
CFLAGS=
compile: sblocks.o descommon.o descracker.o gpu_descommon.o gpu_descracker.o gpu_sblocks.o main.o
	nvcc -o ${OUTPUT} descommon.o gpu_descommon.o gpu_descracker.o gpu_sblocks.o descracker.o sblocks.o main.o

compilec: descommon.o descracker.o sblocks.o mainc.o
	gcc -o ${OUTPUT} descommon.o descracker.o sblocks.o mainc.o

descommon.o: descommon.c
	gcc -c ${CFLAGS} -o descommon.o descommon.c
	
descracker.o: descracker.c
	gcc -c ${CFLAGS} -o descracker.o descracker.c
	
sblocks.o: sblocks.c
	gcc -c ${CFLAGS} -o sblocks.o sblocks.c

mainc.o: main.cu
	gcc -c ${CLFAGS} -o mainc.o main.cu
	
main.o: main.cu
	nvcc -c ${CFLAGS} -o main.o main.cu
	
gpu_descommon.o: gpu_descommon.cu
	nvcc -c ${CFLAGS} -o gpu_descommon.o gpu_descommon.cu	
	
gpu_descracker.o: gpu_descracker.cu
	nvcc -c ${CFLAGS} -o gpu_descracker.o gpu_descracker.cu
	
gpu_sblocks.o: gpu_sblocks.cu
	nvcc -c ${CFLAGS} -o gpu_sblocks.o gpu_sblocks.cu
clean:
	rm *.o ${OUTPUT}
