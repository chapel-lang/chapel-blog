	
%.o: %.f90
	gfortran -c $^

%.exe: %.chpl temperatures.o temperatures.h
	chpl -o $@ $^ --fast

.PHONY: clean
clean: 
	rm *.o *.mod *.exe *.exe_real 
