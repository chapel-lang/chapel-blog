#include <algorithm>
#include <array>
#include <cmath>
#include <iostream>
#include <unordered_map>
#include <variant>
#include <vector>

#include "utils.h"
#include <mpi.h>
#include <omp.h>

void solve_cavity_flow(vector<vector<double>> &p, vector<vector<double>> &u,
                       vector<vector<double>> &v, vector<vector<double>> &b,
                       const int my_space_inner[2][2], const int nt,
                       const int nit, const int world_size, const int my_rank,
                       const double dx, const double dy, const double dt,
                       const double rho, const double nu);

void compute_b(vector<vector<double>> &b, vector<vector<double>> const &u,
               vector<vector<double>> const &v, const int my_space_inner[2][2],
               const double dx, const double dy, const double dt,
               const double rho);

void poisson_kernel(vector<vector<double>> &p, vector<vector<double>> const &pn,
                    vector<vector<double>> const &b,
                    const int my_space_inner[2][2], const double dx,
                    const double dy);

void neumann_bc(vector<vector<double>> &p, const int my_space_inner[2][2]);

void compute_u(vector<vector<double>> &u, vector<vector<double>> const &un,
               vector<vector<double>> const &vn, vector<vector<double>> const &p,
               const int my_space_inner[2][2], const double dx, const double dy,
               const double dt, const double rho, const double nu);

void compute_v(vector<vector<double>> &v, vector<vector<double>> const &un,
               vector<vector<double>> const &vn, vector<vector<double>> const &p,
               const int my_space_inner[2][2], const double dx, const double dy,
               const double dt, const double rho, const double nu);

void update_halos(vector<vector<double>> &a, int my_rank, int world_size,
                  MPI_Status &status);
