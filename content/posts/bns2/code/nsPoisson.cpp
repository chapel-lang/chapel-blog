#include "nsPoisson.h"

int main(int argc, const char *argv[]) {
  // define default values of constants
  unordered_map<string, variant<int, double>> default_args = {
      {"xLen", 2.0},        {"yLen", 2.0},       {"nx", 31},
      {"ny", 31},           {"tolerance", 1e-4}, {"maxIters", 10000},
      {"sourceMag", 100.0}, {"makePlots", 0}};

  // overwrite defaults with command line arguments if present
  parse_args_with_defaults(argc, argv, default_args);

  // set final values of simulation constants
  const double x_len = get<double>(default_args.at("xLen")),
               y_len = get<double>(default_args.at("yLen")),
               l1_tol = get<double>(default_args.at("tolerance")),
               source_mag = get<double>(default_args.at("sourceMag"));
  const int nx = get<int>(default_args.at("nx")),
            ny = get<int>(default_args.at("ny")),
            max_iters = get<int>(default_args.at("maxIters")),
            make_plots = get<int>(default_args.at("makePlots"));

  const double dx = x_len / (nx - 1), dy = y_len / (ny - 1);

  // define pressure and source arrays
  vector<vector<double>> p(ny, vector<double>(nx, 0.0));
  vector<vector<double>> b(ny, vector<double>(nx, 0.0));

  // set boundary conditions
  for (int j = 0; j < ny; j++) {
    p[j][0] = 0;           // p = 0 @ x = 0
    p[j][nx - 1] = j * dy; // p = y @ x = xLen
  }
  for (int i = 0; i < nx; i++) {
    p[0][i] = p[1][i];           // dp/dy = 0 @ y = 0
    p[ny - 1][i] = p[ny - 2][i]; // dp/dy = 0 @ y = yLen
  }

  // set sink/source terms
  b[3 * ny / 4][nx / 4] = source_mag;
  b[ny / 4][3 * nx / 4] = -source_mag;

  // solve and plot
  if (make_plots) {
    plot(p, x_len, y_len, "initial_cpp", "p");
  }

  solve_poisson(p, b, dx, dy, l1_tol, max_iters);

  if (make_plots) {
    plot(p, x_len, y_len, "solution_cpp", "p");
  }

  return 0;
}

void solve_poisson(vector<vector<double>> &p, vector<vector<double>> const &b,
                   const double dx, const double dy, const double tolerance,
                   const int max_iters) {
  // temporary copy of p
  auto pn = p;

#ifdef TERMONTOL
  // solve until tolerance is met or maxIters is reached
  double delta_L1_norm = 1;
  int i = 0;
  while (delta_L1_norm > tolerance && i < max_iters) {
    p.swap(pn);
    poisson_kernel(p, pn, b, dx, dy);
    neumann_bc(p);

    delta_L1_norm = delta_L1(p, pn);
    i++;
  }

  cout << "Converged in " << i << " iterations" << endl;
#else
  // solve for maxIters iterations
  for (int i = 0; i < max_iters; i++) {
    p.swap(pn);
    poisson_kernel(p, pn, b, dx, dy);
    neumann_bc(p);
  }
#endif
}

void poisson_kernel(vector<vector<double>> &p, vector<vector<double>> const &pn,
                    vector<vector<double>> const &b, const double dx,
                    const double dy) {
#pragma omp parallel for
  for (int i = 1; i < p.size() - 1; i++) {
    for (int j = 1; j < p[0].size() - 1; j++) {
      p[i][j] = (dy * dy * (pn[i][j + 1] + pn[i][j - 1]) +
                 dx * dx * (pn[i + 1][j] + pn[i - 1][j]) -
                 dx * dx * dy * dy * b[i][j]) /
                (2.0 * (dx * dx + dy * dy));
    }
  }
}

void neumann_bc(vector<vector<double>> &p) {
  const auto nx = p[0].size();
  const auto ny = p.size();

#pragma omp parallel for
  for (int i = 0; i < nx; i++) {
    p[0][i] = p[1][i];           // dp/dy = 0 @ y = 0
    p[ny - 1][i] = p[ny - 2][i]; // dp/dy = 0 @ y = yLen
  }
}

double delta_L1(vector<vector<double>> const &p,
                vector<vector<double>> const &pn) {
  double diffSum = 0;
  double nSum = 0;


#pragma omp parallel for reduction(+ : diffSum, nSum)
  for (int i = 0; i < p.size(); i++) {
    for (int j = 0; j < p[0].size(); j++) {
      diffSum += abs(p[i][j]) - abs(pn[i][j]);
      nSum += abs(pn[i][j]);
    }
  }

  return diffSum / nSum;
}
