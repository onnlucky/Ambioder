SOURCES:=$(shell ls *.asm)
OBJECTS:=$(SOURCES:.asm=.o)

a.cod a.hex: $(OBJECTS)
	gplink $(OBJECTS)

%.o: %.asm *.inc
	gpasm -p p16f684 -c $<

clean:
	rm -rf *.o *.hex *.lst

run: a.cod
	gpsim a.cod
