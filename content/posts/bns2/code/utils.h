#include <fstream>
#include <iomanip>
#include <iostream>
#include <sstream>
#include <unordered_map>
#include <variant>
#include <vector>

using namespace std;

void plot(vector<vector<double>> const &a, double x_len, double y_len,
          string const &title, string const &varName);

void parse_args_with_defaults(
    int argc, const char *argv[],
    unordered_map<string, variant<int, double>> &defaults);
