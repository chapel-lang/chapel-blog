import os

def read_options_file(options_file):
    if not os.access(options_file, os.R_OK): return ['']

    if os.access(options_file, os.X_OK):
        import subprocess
        output = subprocess.check_output(options_file).decode()
        output = output[:-1] if output.endswith("\n") else output
        return output.split("\n")

    with open(options_file) as file:
        return [line.strip("\n") for line in file]

def compute_options(file):
    base_name = file.removesuffix(".chpl")
    compopts = read_options_file(base_name + ".compopts")
    execopts = read_options_file(base_name + ".execopts")

    if len(compopts) == 1 and len(execopts) == 1:
        return [('', compopts[0], execopts[0])]

    return [(str(i)+'-'+str(j), compopt, execopt)
            for (i, compopt) in enumerate(compopts, start=1)
            for (j, execopt) in enumerate(execopts, start=1)]
