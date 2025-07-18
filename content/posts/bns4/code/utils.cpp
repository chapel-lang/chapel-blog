#include "utils.h"

void print_downsampled(vector<vector<double>> &a, char name,
                       string const &title, int my_rank, int world_size,
                       int downsample_factor, int nx, int ny) {

  string fileName = title + "_" + name + ".dat";

  // write down-sampled chunk of array to file one rank at a time
  for (int p = 0; p < world_size; p++) {

    if (my_rank == p) {
      ofstream dataFile;
      if (my_rank == 0) {
        dataFile.open(fileName, ios::trunc);
      } else {
        dataFile.open(fileName, ios::app);
      }
      dataFile << setprecision(8);

      for (int i = 1; i < a.size() -1; i++) {
        if (i % downsample_factor == 0) {
          bool first = true;
          for (int j = 0; j < a[0].size(); j++) {
            if (j % downsample_factor == 0) {
              if (first) { first = false; } else { dataFile << " "; }
              dataFile << a[i][j];
            }
          }
          dataFile << "\n";
        }
      }
      dataFile.close();
    }
    MPI_Barrier(MPI_COMM_WORLD);
  }
}

void plot(vector<vector<double>> &p, vector<vector<double>> &u,
          vector<vector<double>> &v, int rank, int size, string const &title,
          int downsample_factor, int nx, int ny, double x_len, double y_len) {

  print_downsampled(p, 'p', title, rank, size, downsample_factor, nx, ny);
  print_downsampled(u, 'u', title, rank, size, downsample_factor, nx, ny);
  print_downsampled(v, 'v', title, rank, size, downsample_factor, nx, ny);

  MPI_Barrier(MPI_COMM_WORLD);

  stringstream plotCmd;
  plotCmd << "python3 ./flowPlot.py " << title << " " << x_len << " " << y_len;
  const string plotCmdString = plotCmd.str();
  const char *plotCmdCString = plotCmdString.c_str();
  std::system(plotCmdCString);
}

void parse_args_with_defaults(
    int argc, char *argv[],
    unordered_map<string, variant<int, double>> &defaults) {
  for (int i = 0; i < argc; i++) {
    string arg(argv[i]);
    if (arg[0] == '-' && arg[1] == '-' && arg.find('=') != string::npos) {
      size_t eq_pos = arg.find('=');
      string argName = arg.substr(2, eq_pos - 2);

      auto search = defaults.find(argName);
      if (search != defaults.end()) {
        if (holds_alternative<int>(search->second)) {
          try {
            search->second = stoi(arg.substr(eq_pos + 1, arg.size()));
          } catch (...) {
            cout << "Warning: invalid value for: '" << argName
                 << "'; keeping default value (" << get<int>(search->second)
                 << ")\n";
          }
        } else {
          try {
            search->second = stod(arg.substr(eq_pos + 1, arg.size()));
          } catch (...) {
            cout << "Warning: invalid value for: '" << argName
                 << "'; keeping default value (" << get<double>(search->second)
                 << ")\n";
          }
        }
      } else {
        cout << "Warning: argument: '" << argName
             << "' doesn't have a default value; ignoring\n";
      }
    }
  }
}
