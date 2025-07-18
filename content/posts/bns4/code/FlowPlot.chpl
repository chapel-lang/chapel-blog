use IO, Subprocess;

proc plot(
    const ref p: [?d] real,
    const ref u: [d] real,
    const ref v: [d] real,
    lens: 2*real,
    title: string,
    downsampleFactor: int = 1
) throws {
    const sampleDom = {d.dim(0) by downsampleFactor, d.dim(1) by downsampleFactor};
    const fileNames = [n in ['p', 'u', 'v']] "%s_%s.dat".format(title, n);

    // create data files
    for (arr, fileName) in zip((p, u, v), fileNames) {
        openWriter(fileName, locking=false).write(arr[sampleDom]);
    }

    // call the python plotting script
    Subprocess.spawn([
        "python3",
        "flowPlot.py",
        title,
        lens[0]:string,
        lens[1]:string
    ]);
}
