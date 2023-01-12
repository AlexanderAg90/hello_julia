using BenchmarkTools, Libdl

C_code = raw"""
	#include <stdlib.h>
	#include <math.h>

	double mean(double* vec, size_t n) {
		double sum = 0.0;
		for (size_t i = 0; i < n; i++) {
			sum += vec[i];
		}
		return sum / n;
	}

	double stddev(double* vec, size_t n) {
		double ave = mean(vec, n);
		double disp = 0.0;
		for (size_t i = 0; i < n; i++) {
			double diff = vec[i] - ave;
			disp += diff * diff;
		}
		return sqrt(disp / (n - 1));
	}
""";

const Clib = tempname();

open(`gcc -fPIC -O3 -xc -shared -o $(Clib * "." * Libdl.dlext) -`, "w") do f
    print(f, C_code)
end
  

stddev_c(v::Vector) = ccall(
                        (:stddev, Clib), # ("function_name", library)
                        Float64, # return type from the C library
                        (Ptr{Float64}, Csize_t), # input parameter type to the C function
                        v, length(v) # actual values to pass to C function
                        );

const v = rand(1_000_000);

1 / stddev_c(v)^2

#@benchmark stddev_c(v)