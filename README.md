# README

These codes where used in the HPE Developer Meetup on July 31st 2024 for "Vendor-Neutral GPU Programming in Chapel".

## Prerequisites

These codes require a working install of Chapel. See https://chapel-lang.org/download.html for instructions on how to install Chapel. They are all written to work with either CPUs or GPUs. The GPU codes require an install of Chapel with GPU support (i.e. `CHPL_LOCALE_MODEL=gpu`). For more information on how to install Chapel with GPU support, see https://chapel-lang.org/docs/technotes/gpu.html#setup for more details.

If you wish to run `./05_life --print`, you will need to have `ffmpeg` installed.

## Compiling

All of the examples can be compiled with `chpl --fast <filename>`. For example, to compile `01_simpleSingleGpu.chpl`, you would run `chpl --fast 01_simpleSingleGpu.chpl`. It is recommended to use `--fast` as this will result in optimized generated code.

Depending on how your Chapel compiler is configured, this will result in a binary that works on a CPU or a GPU.
