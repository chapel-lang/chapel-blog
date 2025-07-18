import sys
import pandas as pd
from plotnine import *

if len(sys.argv) != 2:
  print("Usage: ", sys.argv[0], " <Input CSV>")
  exit()

data = pd.read_csv(sys.argv[1])

data['Millions of Elements'] = data['N'] * data['N'] / 1e6
p = ggplot(data, aes(x="Millions of Elements", y="Time (s)", color="Version")) + geom_point() + geom_line()
p.save("times.png")