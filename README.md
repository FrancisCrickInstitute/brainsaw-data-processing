# Pipeline for Stitching BrainSaw Images on HPC

This is a set of scripts to process and stitch individual brainsaw tiles into fused sections. Processing occurs in parallel, so should be much faster than running on a local workstations.

## 1. Prerequisites

You'll need to first install the following in order to run the scripts in this repository.

### 1.1 Download this Repository

There are two different approaches to downloading a git repository:
1. Click the green `Code` dropdown menu above and click `Download ZIP`. Extract the files in the ZIP file to a location in your HPC filesystem - this is where you will run the scripts from.
2. If you are familiar with git, you can just clone the repo. Doing this in a HPC environment should be straightforward using the following commands to first load git and then clone this repository:
    ```shell
    ml git
    git clone git@github.com:FrancisCrickInstitute/brainsaw-data-processing.git
    ```

### 1.2 FIJI

We're going to use a [FIJI](https://fiji.sc/) plugin called [BigStitcher](https://imagej.net/plugins/bigstitcher/) to the stitching, so you will need to install your own version of FIJI - instructions on how to do so are [here](https://franciscrickinstitute.github.io/Image-Analysis-Group/software_instructions/Fiji/).

### 1.3 BigStitcher

Once FIJI is installed, adding new plugins should be very straightforward - instructions on how to install BigStitcher are [here](https://imagej.net/plugins/bigstitcher/#download).

### 1.4 Set up Python Environment

You may have previously used tools such as [pip](https://pip.pypa.io) or [conda](https://docs.conda.io) to set up and manage Python environments. We now recommend [pixi](https://pixi.prefix.dev/) for these tasks - built on top of tools like pip and conda, it is much, much faster than either. Everything you need to set up the environment with pixi is contained the in the [pixi.toml](./pixi.toml) file in this repo. Use the following commands to set up the necessary python environment on HPC, where `path_to_this_repo` is the folder where you downloaded the files in this repository:
```shell
cd <path_to_this_repo>
ml pixi
pixi install
```
## 2. Run Stitching

You now have everything ready to stitch and fuse your images. The scripts in this repo perform two tasks:
1. *Temporary file conversion:* The raw TIF files from the BrainSaw are currently lacking critical metadata. This will hopefully not be the case in the future, but for now, in order to use BigStitcher, we need to load each of the raw TIF files, add the necessary metadata, and then resave the files. This is all handled automatically, but you need to specify a temporary location for the converted files to be stored.
2. *Tile stitching:* BigStitcher is run on the converted files and produces a fused output for each section. Example outputs can be found in the [output-test](./output-test) folder.

> [!IMPORTANT]
> Scripts must be executed from within the directory containing this repository.

To start the stitching process, using the demo data in this repo as an example, run the [submit_all_jobs.sh](./submit_all_jobs.sh) as follows:
```shell
cd <path_to_this_repo>
./submit_all_jobs.sh -i <input_base_dir> -c <converted_base_dir> -s <stitched_base_dir> [-f array_indices] [-n section_indices] [-x]
```
where each parameter specifies the following:

| Parameter Flag | Parameter Description |
| -------------- | --------------------- |
| -i | Input base directory (required) |
| -c | Converted files base directory (required) |
| -s | Stitched output base directory (required) |
| -j | Path to FIJI executable, ImageJ-linux64 (required) |
| -l | Only process input subdirectories containing this text (optional, e.g. 'CrickSaw') |
| -f | File indices to process (optional, e.g. '246,247,248') |
| -n | Section indices to process (optional, e.g. '1,3,5') |
| -x | Delete converted files after successful stitching (optional) |

For example:
```shell
# Full run with cleanup
./submit_all_jobs.sh -i /input -c /converted -s /stitched -j ../Fiji.app/ImageJ-linux64 -x

# Specific tiles and sections, no cleanup
./submit_all_jobs.sh -i /input -c /converted -s /stitched -j ../Fiji.app/ImageJ-linux64 -f "246,247,248" -n "1,3,5"
```
