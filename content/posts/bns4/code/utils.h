#include <chrono>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <sstream>
#include <tuple>
#include <unordered_map>
#include <variant>
#include <vector>

#include <mpi.h>

using namespace std;
using namespace chrono;

void print_downsampled(vector<vector<double>> &a, char name, string const &path,
                       int my_rank, int world_size, int downsample_factor,
                       int nx, int ny);

void plot(vector<vector<double>> &p, vector<vector<double>> &u,
          vector<vector<double>> &v, int rank, int size, string const &title,
          int downsample_factor, int nx, int ny, double x_len, double y_len);

void parse_args_with_defaults(
    int argc, char *argv[],
    unordered_map<string, variant<int, double>> &defaults);

class Timer {
    high_resolution_clock::time_point start;

public:
  Timer() {
    MPI_Barrier(MPI_COMM_WORLD);
    start = high_resolution_clock::now();
  }

  double elapsed() {
    MPI_Barrier(MPI_COMM_WORLD);
    auto stop = high_resolution_clock::now();
    duration<double> runtime = duration_cast<duration<double>>(stop - start);
    return runtime.count();
  }
};
