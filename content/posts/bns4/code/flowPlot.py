import sys
import numpy as np
import matplotlib.pyplot as plt
from matplotlib import cm

title = sys.argv[1]

p = np.loadtxt(f"{title}_p.dat", delimiter=' ')
u = np.loadtxt(f"{title}_u.dat", delimiter=' ')
v = np.loadtxt(f"{title}_v.dat", delimiter=' ')

x_len = float(sys.argv[2])
y_len = float(sys.argv[3])

x = np.linspace(0, x_len, p.shape[1])
y = np.linspace(0, y_len, p.shape[0])
X, Y = np.meshgrid(x, y)

fig, ax = plt.subplots(1, 2,  figsize=(11,7), dpi=100)
cf = ax[1].contourf(X, Y, p, alpha=0.5, cmap=cm.viridis)
fig.colorbar(cf, label='Pressure')

ax[0].quiver(X, Y, u, v)
ax[0].set_title("Quiver Flow Plot")

ax[1].streamplot(X, Y, u, v)
ax[1].set_xlabel('x')
ax[1].set_ylabel('y')
ax[1].set_title("Pressure Gradient")

fig.suptitle(title)
plt.savefig(title + '.png')
