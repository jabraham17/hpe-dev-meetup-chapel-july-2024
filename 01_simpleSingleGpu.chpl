use GpuDiagnostics;
import RangeChunk;

/* Config constants automatically get command line flags */
config const n = 100;
config const print = false;
config const verboseGpu = false;

/* Determine the compute node to use */
const hasGpus = here.gpus.size > 0;
const targetLocale = if hasGpus then here.gpus[0] else here;

/* Create an array on the target node */
const elmRange = 0..<n;
on targetLocale var Arr: [elmRange] real(32);


if verboseGpu then startVerboseGpu();
/* Move computation to the compute node that owns the array and run a parallel loop */
on Arr {
  forall i in elmRange {
    Arr[i] = i;
  }
  /* We can also use a more familiar array syntax */
  Arr += 1;
}
if verboseGpu then stopVerboseGpu();

if print then writeln(Arr);
