import numpy as np
import sys

# Parameters
nx = int(sys.argv[1])
ny = int(sys.argv[2])
nt = 10000
xmin = 0
xmax = float(sys.argv[3])
ymin = 0
ymax = float(sys.argv[4])
sourceMag = 500

dx = (xmax - xmin) / (nx - 1)
dy = (ymax - ymin) / (ny - 1)

y = np.linspace(xmin, xmax, ny)

# Initialization
p  = np.zeros((ny, nx))
pd = np.zeros((ny, nx))
b  = np.zeros((ny, nx))

# Source
b[int(3 * ny / 4), int(nx / 4)]  = sourceMag
b[int(ny / 4), int(3 * nx / 4)] = -sourceMag

# Boundary
p[:, 0] = 0  # p = 0 @ x = 0
p[:, -1] = y  # p = y @ x = 2
p[0, :] = p[1, :]  # dp/dy = 0 @ y = 0
p[-1, :] = p[-2, :]  # dp/dy = 0 @ y = 1


for it in range(nt):
    pd = p.copy()

    # poisson equation
    p[1:-1, 1:-1] = (((pd[1:-1, 2:] + pd[1:-1, :-2]) * dy**2 +
                     (pd[2:, 1:-1] + pd[:-2, 1:-1]) * dx**2 -
                     b[1:-1, 1:-1] * dx**2 * dy**2) /
                     (2 * (dx**2 + dy**2)))

    # neumann bc
    p[0, :] = p[1, :]  # dp/dy = 0 @ y = 0
    p[-1, :] = p[-2, :]  # dp/dy = 0 @ y = 1
