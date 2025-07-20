use IO;

config const numTasks = here.maxTaskPar;

coforall loc in Locales do
  on loc do
    coforall tid in 0..<numTasks do
      writef("Hello from task %i out of %i from locale %i out of %i on %s\n",
             tid, numTasks, here.id, Locales.size, here.name);
