import sys
import pandas as pd
from plotnine import *

if len(sys.argv) != 2:
  print("Usage: ", sys.argv[0], " <Input CSV>")
  exit()

data = pd.read_csv(sys.argv[1])
data['Millions of Elements'] = data['N'] * data['N'] * data['N'] / 1e6
data = data[data['Version'] != 'Distributed 4 Nodes']

p = ggplot(data, aes(x="Millions of Elements", y="Time (s)", color="Version")) + geom_point() + geom_line()
p.save("distributedComparison.png")

data = data[data['Version'] != 'Sequential']

p = ggplot(data, aes(x="Millions of Elements", y="Time (s)", color="Version")) + geom_point() + geom_line()
p.save("distributedComparisonParallelOnly.png")