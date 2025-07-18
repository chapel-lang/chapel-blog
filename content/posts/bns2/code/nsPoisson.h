#include "utils.h"
#include <cmath>
#include <iostream>
#include <omp.h>
#include <unordered_map>
#include <variant>
#include <vector>

using namespace std;

void solve_poisson(vector<vector<double>> &p, vector<vector<double>> const &b,
                   double dx, double dy, double tolerance, int max_iters);

void poisson_kernel(vector<vector<double>> &p, vector<vector<double>> const &pn,
                    vector<vector<double>> const &b, double dx, double dy);

void neumann_bc(vector<vector<double>> &p);
double delta_L1(const vector<vector<double>> &p,
                const vector<vector<double>> &pn);
