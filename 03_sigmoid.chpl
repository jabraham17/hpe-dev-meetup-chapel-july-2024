use GpuDiagnostics;
import RangeChunk;
use Random;
use Math;

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

/* Initialize the array to get more interesting data */
fillRandom(HostArr, -6, 6);

/* Using the sigmoid function: `Xi = 1 / (1 + exp(-Xi))` */

if verboseGpu then startVerboseGpu();
coforall i in 0..<nChunks {
  on targetLocales[i] {
    const chunk = RangeChunk.chunk(elmRange, nChunks, i);
    var DeviceArr = HostArr[chunk];
    /* This expression will become a single GPU kernel, or a vector-eligible loop */
    DeviceArr = 1 / (1 + exp(-DeviceArr));
    HostArr[chunk] = DeviceArr;
  }
}
if verboseGpu then stopVerboseGpu();

if print then writeln(HostArr);
