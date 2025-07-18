# polyfit.py
#
# Usage:
#   python3 -m venv myenv                           # Create virtual environment
#   source myenv/bin/activate                       # Activate on macOS/Linux
#   pip install numpy scikit-learn                  # Install required packages
#   python3 polyfit.py --degree=3 --alpha_order=-2  # Run the script
#
# A Python script for polynomial curve fitting using two parameters:
# the degree of the polynomial and the regularization strength (alpha). The code
# leverages numpy and scikit-learn libraries to fit the model to some sample
# data.
#
# For illustrating hyperparameter tuning with the tune.chpl program,
# we will use this script to tune the degree of the polynomial and
# the order of magnitude of the regularization strength (alpha).
#

# Import necessary libraries
import numpy as np
from sklearn.preprocessing import PolynomialFeatures
from sklearn.linear_model import Ridge
from sklearn.pipeline import make_pipeline
import sys

# Generate sample data
np.random.seed(0)
X = np.sort(np.random.rand(100, 1), axis=0)
y = np.sin(2 * np.pi * X).ravel() + np.random.randn(100) * 0.1

# Parameters

# read the degree of the polynomial from the command line --degree=val
degree_arg = "2"    # Default value of polynomial degree 2
for arg in sys.argv[1:]:
    if arg.startswith("--degree="):
        degree_arg = arg.split("=")[1]
        break
# Set degree to the integer value of val
degree = int(degree_arg)

# read the order of magnitude of the regularization strength from the command
# line
# --alpha_order=val
alpha_order_arg = "-1"  # Default value of alpha_order -1
for arg in sys.argv[1:]:
    if arg.startswith("--alpha_order="):
        alpha_order_arg = arg.split("=")[1]
        break
# Set alpha_order to the integer value of val
alpha_order = int(alpha_order_arg)
# Set the regularization strength, alpha, to 10^alpha_order
alpha = 10 ** alpha_order

# Create a polynomial model with Ridge regularization
model = make_pipeline(PolynomialFeatures(degree), Ridge(alpha=alpha))
model.fit(X, y)

# Generate predictions
X_test = np.linspace(0, 1, 100).reshape(-1, 1)
y_pred = model.predict(X_test)

# Compute the root mean squared error
rmse = np.sqrt(np.mean((model.predict(X) - y) ** 2))
print(rmse)
