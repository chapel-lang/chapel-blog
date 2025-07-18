use FlowPlot;
use StencilDist;
use Time;

// set up simulation constants
config const xLen = 2.0,
             yLen = 2.0,
             nx = 41,
             ny = 41,
             nt = 500,
             nit = 50,
             dt = 0.001,
             rho = 1.0,
             nu = 0.1;

const dx = xLen / (nx - 1),
      dy = yLen / (ny - 1);

// simulation settings
config const createPlots = false,
             downsampleFactor = 2;

// define distributed 2D domains
const tl = reshape(Locales, {0..<Locales.size, 0..0}),
      space = stencilDist.createDomain({0..<ny, 0..<nx}, fluff=(1,1), targetLocales=tl),
      spaceInner = space.expand(-1);

proc main() {
    // define distributed arrays
    var p, u, v : [space] real;

    // apply boundary conditions
    u[0,    ..] = 1.0;
    u[ny-1, ..] = -1.0;

    // run simulation
    if createPlots then plot(p, u, v, (xLen, yLen), title="Initial", downsampleFactor);
    var t = new stopwatch();
    t.start();

    solveCavityFlow(p, u, v);

    writeln("Ran simulation in ", t.elapsed(), " seconds");
    if createPlots then plot(p, u, v, (xLen, yLen), title="Solution", downsampleFactor);

    // print result
    writef("mean pressure: %.4r\n", + reduce p / p.size);
}

proc solveCavityFlow(ref p, ref u, ref v) {
    // temporary copies of p, u, and v
    var pn = p,
        un = u,
        vn = v;

    // source term for pressure
    var b : [space] real;

    for 1..nt {
        u <=> un;
        v <=> vn;

        // compute the portion of p that depends only on u and v
        computeB(b, un, vn);
        b.updateFluff();

        // iteratively solve for p
        for 1..nit {
            p <=> pn;
            poissonKernel(p, pn, b);
            neumannBC(p);
            p.updateFluff();
        }

        // compute u and v
        computeU(u, un, vn, p);
        computeV(v, un, vn, p);
        u.updateFluff();
        v.updateFluff();
    }
}

proc computeB(ref b, const ref u, const ref v) {
    forall (i, j) in spaceInner {
        const du = u[i, j+1] - u[i, j-1],
              dv = v[i+1, j] - v[i-1, j];

        b[i, j] = rho * ((1.0 / dt) * (du / (2.0 * dx) + dv / (2.0 * dy)) -
                         (du / (2.0 * dx))**2 -
                         (dv / (2.0 * dy))**2 -
                         2.0 * ((u[i+1, j] - u[i-1, j]) / (2.0 * dy) *
                                (v[i, j+1] - v[i, j-1]) / (2.0 * dx)));
    }
}

proc poissonKernel(ref p: [] real, const ref pn: [] real, const ref b: [] real) {
    forall (i, j) in spaceInner {
        p[i, j] = (dy**2 * (pn[i, j+1] + pn[i, j-1]) +
                   dx**2 * (pn[i+1, j] + pn[i-1, j]) -
                   dx**2 * dy**2 * b[i, j]) /
                   (2.0 * (dx**2 + dy**2));
    }
}

proc neumannBC(ref p) {
    p[.., 0] = p[.., 1];
    p[.., nx - 1] = p[.., nx - 2];
}

proc computeU(ref u, const ref un, const ref vn, const ref p) {
    forall (i, j) in spaceInner {
        u[i, j] = un[i, j] - un[i, j] * (dt / dx) * (un[i, j] - un[i, j-1]) -
                             vn[i, j] * (dt / dy) * (un[i, j] - un[i-1, j]) -
                  dt / (2.0 * rho * dx) * (p[i, j+1] - p[i, j-1]) +
                  nu * ((dt / dx**2) *
                            (un[i, j+1] - 2.0 * un[i, j] + un[i, j-1]) +
                        (dt / dy**2) *
                            (un[i+1, j] - 2.0 * un[i, j] + un[i-1, j]));
    }
}

proc computeV(ref v, const ref un, const ref vn, const ref p) {
    forall (i, j) in spaceInner  {
        v[i, j] = vn[i, j] - un[i, j] * (dt / dx) * (vn[i, j] - vn[i, j-1]) -
                             vn[i, j] * (dt / dy) * (vn[i, j] - vn[i-1, j]) -
                  dt / (2.0 * rho * dy) * (p[i+1, j] - p[i-1, j]) +
                  nu * ((dt / dx**2) *
                            (vn[i, j+1] - 2.0 * vn[i, j] + vn[i, j-1]) +
                        (dt / dy**2) *
                            (vn[i+1, j] - 2.0 * vn[i, j] + vn[i-1, j]));
    }
}
