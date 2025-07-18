#include "utils.h"

void plot(vector<vector<double>> const &a, double x_len, double y_len,
          string const &title, string const &varName) {
  const auto nx = a[0].size();
  const auto ny = a.size();
  const auto file_name = title + ".dat";

  // print array data
  ofstream dataFile;
  dataFile.open(file_name);

  // write data
  dataFile << setprecision(10);
  for (int i = 0; i < ny; i++) {
    for (int j = 0; j < nx; j++) {
      if (j > 0) {
        dataFile << " ";
      }
      dataFile << a[i][j];
    }
    dataFile << "\n";
  }
  dataFile.close();

  // call the python plotting script
  stringstream plotCmd;
  plotCmd << "python3 surfPlot.py " << file_name << " " << title << " "
          << varName << " " << x_len << " " << y_len;
  const string plotCmdStr = plotCmd.str();
  const char *plotCmdCString = plotCmdStr.c_str();
  std::system(plotCmdCString);
}

void parse_args_with_defaults(
    int argc, const char *argv[],
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
