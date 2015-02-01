SOURCES:=$(shell ls *.asm)
OBJECTS:=$(SOURCES:.asm=.o)

fw: $(OBJECTS)
	echo gplink $(OBJECTS)

%.o: %.asm *.inc
	gpasm -p p16f684 -c $<

clean:
	rm -rf *.o *.hex *.lst
