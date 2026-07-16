# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A pipeline for stitching BrainSaw microscope tile images into fused sections on an HPC (SLURM) cluster. It's a thin orchestration layer around FIJI/BigStitcher, not a standalone application: Python handles metadata repair and format conversion, shell scripts handle SLURM job submission/dependencies, and an ImageJ macro drives the actual stitching.

## Environment setup

Uses [pixi](https://pixi.prefix.dev/) (see `pixi.toml`/`pixi.lock`), not raw pip/conda.

```shell
ml pixi          # on HPC, load the pixi module first
pixi install      # creates the `bioio` environment from pixi.toml
pixi run python <script>.py ...
```

There are no lint/test commands configured in this repo (no test suite, linter, or CI config exists).

## Pipeline architecture

The pipeline is a SLURM job chain, orchestrated per input subdirectory (one subdirectory = one section):

1. **`submit_all_jobs.sh`** — entry point. For each matching input subdirectory, submits a positions job (`prepare_positions.sh`), then an array job (`ome_convert.sh`, `--dependency=afterok` on the positions job), then a dependent stitching job (`run_bigstitcher.sh`, `--dependency=afterok` on the array job), and optionally a cleanup job (`--dependency=afterany`) that deletes converted files once fused output exists. Directory selection can be filtered by label (`-l`) or restricted to specific section indices (`-n`); tile conversion can be restricted to specific array indices (`-f`).
2. **`prepare_positions.sh`** / **`mat_to_csv.py`** — ensures `tilePositions.csv` exists in the input section directory before conversion starts, converting it from `tilePositions.mat` (BrainSaw's raw stage-position export, key `positionArray`) if the CSV isn't already there. Runs once per section, ahead of the conversion array job, to avoid every array task racing to generate the same file.
3. **`ome_convert.sh`** — SLURM array task. Each array index maps to one raw `.tif` tile in the input directory (files sorted, indexed by `$SLURM_ARRAY_TASK_ID`). Calls `convert_brainsaw_tiffs.py` on that tile plus the section's `tilePositions.csv`.
4. **`convert_brainsaw_tiffs.py`** — repairs missing OME metadata on a single raw tile: parses the tile/z index from the filename (`hml-(\d{4})_(\d{5})\.tif`), looks up that tile's stage position from `tilePositions.csv`, builds OME `Pixels`/`Plane`/`TiffData` metadata (stage position, physical pixel sizes), int16→uint16-safe conversion if needed, and writes an OME-TIFF via `bioio`.
5. **`run_bigstitcher.sh`** — runs FIJI headless (`ml Java/1.8`) against `Run_BigStitcher.ijm` on the converted directory, with a 5-minute timeout.
6. **`Run_BigStitcher.ijm`** — defines a BigStitcher multi-view dataset from the converted OME-TIFFs (re-saved as multiresolution HDF5), calculates pairwise shifts (phase correlation), filters/optimizes shifts globally, then fuses and saves per-timepoint/channel TIFF stacks to the output directory.

Key invariant: **stage positions and tile/z indices are correlated by row position** in `tilePositions.csv` (`positions.iloc[tile_index - 1]`), not by any ID column — the CSV row order must match the tile numbering encoded in filenames.

`input-test/` and `output-test/` are small real example datasets (two sections) used to demonstrate/verify the pipeline end-to-end; `output-test` shows the expected final fused output shape.

## Conventions specific to this repo

- All pipeline scripts assume execution from the repository root (paths like `./ome_convert.sh`, `./Run_BigStitcher.ijm` are relative).
- SLURM scripts pass parameters between jobs via `--export` environment variables (`INPUT_DIR`, `OUTPUT_DIR`, `FIJI_PATH`), not command-line args.
- FIJI must be run headless with `Java/1.8` (`ml Java/1.8`) specifically — this is required by the BigStitcher/FIJI version in use.