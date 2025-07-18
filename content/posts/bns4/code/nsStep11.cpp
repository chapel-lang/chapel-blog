#include "nsStep11.h"

/*
    Array distribution scheme:

    |---------- (nx == my_nx) --------|

    *---------------------------------*
    | xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx |    ---     ---
    |                                 |     |       |
    |             rank 0              |  (my_ny)    |
    |                                 |     |       |
    | =============================== |    ---      |
    *---------------------------------*             |
    | =============================== |             |
    |                                 |             |
    |             rank 1              |             |
    |                                 |             |
    | =============================== |            (ny)
    *---------------------------------*             |
    .                .                .             |
    .                .                .             |
    .                .                .             |
    *---------------------------------*             |
    | =============================== |             |
    |                                 |             |
    |             rank N              |             |
  ^ |                                 |             |
  | | xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx |            ---
  Y *---------------------------------*
    X ->

    Key:
    ------------------------
    * ==== : halo buffer (holds neighbor's values after 'update_halos' is called)
    * xxxx : unused halo buffer
*/

int main(int argc, char *argv[]) {
  // initialize MPI
  MPI_Init(&argc, &argv);
  int size, rank;
  MPI_Comm_size(MPI_COMM_WORLD, &size);
  MPI_Comm_rank(MPI_COMM_WORLD, &rank);

  // define default values of constants
  unordered_map<string, variant<int, double>> default_args = {
      {"xLen", 2.0},     {"yLen", 2.0},
      {"nx", 41},        {"ny", 41},
      {"nt", 500},       {"nit", 50},
      {"dt", 0.001},     {"rho", 1.0},
      {"nu", 0.1},       {"downsampleFactor", 2},
      {"createPlots", 0}};

  // overwrite defaults with command line arguments if present
  parse_args_with_defaults(argc, argv, default_args);

  const double x_len = get<double>(default_args.at("xLen")),
               y_len = get<double>(default_args.at("yLen")),
               dt = get<double>(default_args.at("dt")),
               rho = get<double>(default_args.at("rho")),
               nu = get<double>(default_args.at("nu"));

  const int nx = get<int>(default_args.at("nx")),
            ny = get<int>(default_args.at("ny")),
            nt = get<int>(default_args.at("nt")),
            nit = get<int>(default_args.at("nit")),
            downsample_factor = get<int>(default_args.at("downsampleFactor")),
            create_plots = get<int>(default_args.at("createPlots"));

  const double dx = x_len / (nx - 1), dy = y_len / (ny - 1);

  // define the sizes of the local sub-arrays - not including halos
  // (give remainder elements to rank 0)
  // { my_ny, my_nx }
  const int my_space[2] = {ny / size + (rank == 0 ? ny % size : 0), nx};

  // define the iteration bounds
  // (halos on the north and south edges of the global domain are unused)
  // { {y_start, y_stop}, {x_start, x_stop} }
  const int my_space_inner[2][2] = {
      {(rank == 0) ? 2 : 1, my_space[0] + ((rank == size - 1) ? 0 : 1)},
      {1, my_space[1] - 1}};

  // initialize this rank's portion of distributed arrays
  vector<vector<double>> p(my_space[0] + 2, vector<double>(my_space[1], 0.0));
  vector<vector<double>> u(my_space[0] + 2, vector<double>(my_space[1], 0.0));
  vector<vector<double>> v(my_space[0] + 2, vector<double>(my_space[1], 0.0));
  vector<vector<double>> b(my_space[0] + 2, vector<double>(my_space[1], 0.0));

  // apply boundary conditions
  if (rank == 0) {
    for (int j = 0; j < my_space[1]; j++) {
      u[1][j] = 1.0;
    }
  }

  if (rank == size - 1) {
    for (int j = 0; j < my_space[1]; j++) {
      u[u.size() - 2][j] = -1.0;
    }
  }

  // run simulation
  if (create_plots) {
    plot(p, u, v, rank, size, "Initial", downsample_factor, nx, ny, x_len,
         y_len);
  }
  auto t = new Timer();

  solve_cavity_flow(p, u, v, b, my_space_inner, nt, nit, size, rank, dx, dy, dt,
                    rho, nu);

  double elapsed = t->elapsed();
  if (rank == 0) {
    cout << "Ran simulation in " << elapsed << " seconds\n";
  }
  if (create_plots) {
    plot(p, u, v, rank, size, "Solution", downsample_factor, nx, ny, x_len,
         y_len);
  }

  // print result
  double pressure_sum = 0.0;
#pragma omp parallel for reduction(+ : pressure_sum)
  for (int i = my_space_inner[0][0]; i < my_space_inner[0][1]; i++) {
    for (int j = my_space_inner[1][0]; j < my_space_inner[1][1]; j++) {
      pressure_sum += p[i][j];
    }
  }

  double pressure_mean[2] = {pressure_sum, double(my_space[0] * my_space[1])},
         global_pressure_mean[2] = {0.0, 0.0};

  MPI_Reduce(pressure_mean, global_pressure_mean, 2, MPI_DOUBLE, MPI_SUM, 0,
             MPI_COMM_WORLD);

  if (rank == 0) {
    printf("mean pressure: %.4f\n",
           global_pressure_mean[0] / global_pressure_mean[1]);
  }

  MPI_Finalize();
  return 0;
}

void solve_cavity_flow(vector<vector<double>> &p, vector<vector<double>> &u,
                       vector<vector<double>> &v, vector<vector<double>> &b,
                       const int my_space_inner[2][2], const int nt,
                       const int nit, const int world_size, const int my_rank,
                       const double dx, const double dy, const double dt,
                       const double rho, const double nu) {
  auto pn = p;
  auto un = u;
  auto vn = v;
  MPI_Status status;

  for (int i = 0; i < nt; i++) {
    MPI_Barrier(MPI_COMM_WORLD);
    u.swap(un);
    v.swap(vn);

    // compute the portion of p that depends only on u and v
    compute_b(b, un, vn, my_space_inner, dx, dy, dt, rho);
    MPI_Barrier(MPI_COMM_WORLD);
    update_halos(b, my_rank, world_size, status);
    MPI_Barrier(MPI_COMM_WORLD);

    // iteratively solve for p
    for (int p_iter = 0; p_iter < nit; p_iter++) {
      p.swap(pn);
      poisson_kernel(p, pn, b, my_space_inner, dx, dy);
      neumann_bc(p, my_space_inner);
      MPI_Barrier(MPI_COMM_WORLD);
      update_halos(p, my_rank, world_size, status);
      MPI_Barrier(MPI_COMM_WORLD);
    }

    // compute u and v
    compute_u(u, un, vn, p, my_space_inner, dx, dy, dt, rho, nu);
    compute_v(v, un, vn, p, my_space_inner, dx, dy, dt, rho, nu);
    MPI_Barrier(MPI_COMM_WORLD);
    update_halos(u, my_rank, world_size, status);
    update_halos(v, my_rank, world_size, status);
  }
}

void compute_b(vector<vector<double>> &b, vector<vector<double>> const &u,
               vector<vector<double>> const &v, const int my_space_inner[2][2],
               const double dx, const double dy, const double dt,
               const double rho) {
  double du, dv;

#pragma omp parallel for private(du, dv)
  for (int i = my_space_inner[0][0]; i < my_space_inner[0][1]; i++) {
    for (int j = my_space_inner[1][0]; j < my_space_inner[1][1]; j++) {
      du = u[i][j + 1] - u[i][j - 1];
      dv = v[i + 1][j] - v[i - 1][j];

      b[i][j] = rho * ((1.0 / dt) * (du / (2.0 * dx) + dv / (2.0 * dy)) -
                       pow(du / (2.0 * dx), 2) - pow(dv / (2.0 * dy), 2) -
                       2.0 * ((u[i + 1][j] - u[i - 1][j]) / (2.0 * dy) *
                              (v[i][j + 1] - v[i][j - 1]) / (2.0 * dx)));
    }
  }
}

void poisson_kernel(vector<vector<double>> &p, vector<vector<double>> const &pn,
                    vector<vector<double>> const &b,
                    const int my_space_inner[2][2], const double dx,
                    const double dy) {
#pragma omp parallel for
  for (int i = my_space_inner[0][0]; i < my_space_inner[0][1]; i++) {
    for (int j = my_space_inner[1][0]; j < my_space_inner[1][1]; j++) {
      p[i][j] = (dy * dy * (pn[i][j + 1] + pn[i][j - 1]) +
                 dx * dx * (pn[i + 1][j] + pn[i - 1][j]) -
                 dx * dx * dy * dy * b[i][j]) /
                (2.0 * (dx * dx + dy * dy));
    }
  }
}

void neumann_bc(vector<vector<double>> &p, const int my_space_inner[2][2]) {
#pragma omp parallel for
  for (int i = my_space_inner[0][0]; i < my_space_inner[0][1]; i++) {
    p[i][my_space_inner[1][0] - 1] = p[i][my_space_inner[1][0]];
    p[i][my_space_inner[1][1]] = p[i][my_space_inner[1][1] - 1];
  }
}

void compute_u(vector<vector<double>> &u, vector<vector<double>> const &un,
               vector<vector<double>> const &vn,
               vector<vector<double>> const &pn, const int my_space_inner[2][2],
               const double dx, const double dy, const double dt,
               const double rho, const double nu

) {
#pragma omp parallel for
  for (int i = my_space_inner[0][0]; i < my_space_inner[0][1]; i++) {
    for (int j = my_space_inner[1][0]; j < my_space_inner[1][1]; j++) {
      u[i][j] = un[i][j] - un[i][j] * (dt / dx) * (un[i][j] - un[i][j - 1]) -
                vn[i][j] * (dt / dy) * (un[i][j] - un[i - 1][j]) -
                dt / (2.0 * rho * dx) * (pn[i][j + 1] - pn[i][j - 1]) +
                nu * ((dt / (dx * dx)) *
                          (un[i][j + 1] - 2.0 * un[i][j] + un[i][j - 1]) +
                      (dt / (dy * dy)) *
                          (un[i + 1][j] - 2.0 * un[i][j] + un[i - 1][j]));
    }
  }
}

void compute_v(vector<vector<double>> &v, vector<vector<double>> const &un,
               vector<vector<double>> const &vn,
               vector<vector<double>> const &pn, const int my_space_inner[2][2],
               const double dx, const double dy, const double dt,
               const double rho, const double nu) {
#pragma omp parallel for
  for (int i = my_space_inner[0][0]; i < my_space_inner[0][1]; i++) {
    for (int j = my_space_inner[1][0]; j < my_space_inner[1][1]; j++) {
      v[i][j] = vn[i][j] - un[i][j] * (dt / dx) * (vn[i][j] - vn[i][j - 1]) -
                vn[i][j] * (dt / dy) * (vn[i][j] - vn[i - 1][j]) -
                dt / (2.0 * rho * dy) * (pn[i + 1][j] - pn[i - 1][j]) +
                nu * ((dt / (dx * dx)) *
                          (vn[i][j + 1] - 2.0 * vn[i][j] + vn[i][j - 1]) +
                      (dt / (dy * dy)) *
                          (vn[i + 1][j] - 2.0 * vn[i][j] + vn[i - 1][j]));
    }
  }
}

// copy the edges of each sub-array into the neighboring rank's halos
// (don't update rank 0's north halo or rank n's south halo)
void update_halos(vector<vector<double>> &a, int my_rank, int world_size,
                  MPI_Status &status) {
  const int nx = a[0].size();

  // send south edge to southern neighbor
  if (my_rank < world_size - 1) {
    MPI_Send(&a[a.size() - 2][0], nx, MPI_DOUBLE, my_rank + 1, 1,
             MPI_COMM_WORLD);
  }
  // receive north edge from northern neighbor
  if (my_rank > 0) {
    MPI_Recv(&a[0][0], nx, MPI_DOUBLE, my_rank - 1, 1, MPI_COMM_WORLD, &status);
  }

  // send north edge to northern neighbor
  if (my_rank > 0) {
    MPI_Send(&a[1][0], nx, MPI_DOUBLE, my_rank - 1, 2, MPI_COMM_WORLD);
  }
  // receive south edge from southern neighbor
  if (my_rank < world_size - 1) {
    MPI_Recv(&a[a.size() - 1][0], nx, MPI_DOUBLE, my_rank + 1, 2,
             MPI_COMM_WORLD, &status);
  }
}
