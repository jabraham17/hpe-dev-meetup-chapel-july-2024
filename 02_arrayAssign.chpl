use GpuDiagnostics;
import RangeChunk;

/* Config constants automatically get command line flags */
config const n = 100;
config const print = false;
config const verboseGpu = false;

/* Determine the compute nodes to use.
   For the CPU case we are using an array of the same locale. */
const hasGpus = here.gpus.size > 0;
const nLocales = if hasGpus then here.gpus.size else here.maxTaskPar;
var targetLocales: [0..<nLocales] locale;
if hasGpus then targetLocales = here.gpus;
           else targetLocales = here;

/* Create a local array that will be chunked up across the GPUs (or CPU tasks) */
const elmRange = 0..<n;
var HostArr: [elmRange] real(32);
const nChunks = nLocales;

if verboseGpu then startVerboseGpu();
/* 'coforall' creates a task per iteration of the loop */
coforall i in 0..<nChunks {
  /* On each compute node, set a chunk of the array to the index of the current iteration */
  on targetLocales[i] {
    const chunk = RangeChunk.chunk(elmRange, nChunks, i);
    var DeviceArr = HostArr[chunk];
    DeviceArr = i+1;
    HostArr[chunk] = DeviceArr;
  }
}
if verboseGpu then stopVerboseGpu();

if print then writeln(HostArr);
