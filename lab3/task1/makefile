all: start

start: start.o
	ld -m elf_i386 -o start start.o

start.o: start.s
	nasm -f elf32 -o start.o start.s

clean:
	rm -f start.o start
