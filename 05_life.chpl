use Random;
use Image;
use GpuDiagnostics;

/* Width of the image */
config const width = 20;
/* Height of the image */
config const height = 20;
/* Initial percentage of live cells */
config const percent = 20;
/* Maximum number of generations */
config const maxGenerations = 10;
/* Print the grid at each iteration */
config const print = false;
/* Verbose GPU output */
config const verboseGpu = false;

/* Where to do the work, GPU if available or CPU */
const hasGpus = here.gpus.size > 0;
const targetLocale = if hasGpus then here.gpus[0] else here;

/* Define the domain of the grid, the grid arrays will be defined over this domain */
on targetLocale const D = {0..<height, 0..<width};
on targetLocale const Halo = D.expand(1);

/* Define the grid on the locale where the work will be done*/
on targetLocale var Grid: [Halo] bool;
on targetLocale var NextGrid: [Halo] bool;

/* Initialize the grid to a random state */
initGrid(Grid, D, percent);

/* If we are using a GPU we can print the communication that happens */
if verboseGpu then startVerboseGpu();

/* Move computation to the compute locale */
on targetLocale {
  const DD = D; // localize the domain
  var neq: [DD] bool;
  for 1..maxGenerations {
    /*
      For each cell, compute the next cell.
      This is where the computation happens and will become a kernel launch if
      'node' is a GPU.
    */
    forall idx in DD {
      computeCell(Grid, NextGrid, idx);
      /* Check if the grid has stabilized */
      neq[idx] = Grid[idx] != NextGrid[idx];
    }

    /* This reduction will also result in a kernel launch */
    const stable = + reduce neq;
    if !stable then break;

    /* Swapping 2 GPU arrays in O(1) */
    Grid <=> NextGrid;

    printGrid(Grid);
  }
}

if verboseGpu then stopVerboseGpu();

/*
  Compute the next state for cell at `idx`, storing it in `NextGrid`.

  The Game Of Life rules are as follows
    - Any live cell with fewer than two live neighbors dies, as if by underpopulation.
    - Any live cell with two or three live neighbors lives on to the next generation.
    - Any live cell with more than three live neighbors dies, as if by overpopulation.
    - Any dead cell with exactly three live neighbors becomes a live cell, as if by reproduction.
*/
inline proc computeCell(Grid, ref NextGrid, idx) {
  const (i,j) = idx;
  const neighbors = Grid[i-1,j-1] + Grid[i-1,j] + Grid[i-1,j+1] +
                    Grid[i  ,j-1] +               Grid[i  ,j+1] +
                    Grid[i+1,j-1] + Grid[i+1,j] + Grid[i+1,j+1];
  NextGrid[i,j] = neighbors == 3 || neighbors == 2 && Grid[i,j];
}

/*
  Initialize the grid to a random state with `p` percentage of live cells.

  Note that we fill an array `rand` and then set the grid to true if `rand` meets our threshold. This avoids fine grained host->device communication.
*/
proc initGrid(ref Grid, D, p) {
  var rs = new randomStream(eltType=real);

  const DD = D; // make sure to localize the domain
  var rand: [DD] bool;
  forall (r, elm) in zip(rand, rs.next(DD)) do
    r = elm <= p:real / 100;

  Grid[D] = rand;
}


/* Print helpers to write an image of the automaton */
proc printGrid(Grid) {
  if !print then return;

  inline proc writeImage(grid: []) {
    @functionStatic
    ref pipe = try! new mediaPipe("life.mp4", imageType.bmp);

    var pixels =
      scale(
        interpolateColor(grid, 0x000000, 0x00FF00, colorRange=(false, true)),
        4
      );
    try! pipe.writeFrame(pixels);
  }

  on Locales[0] {
    var localGrid = Grid;
    writeImage(localGrid);
  }
}
