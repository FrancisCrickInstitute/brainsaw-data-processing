# Pipeline for Stitching BrainSaw Images on HPC

## 0. Prerequisites

You'll need to first install the following in order to run the scripts in this repository.

### 0.1 Download this Repository

There are two different approaches to downloading a git repository:
1. Click the green `Code` dropdown menu above and click `Download ZIP`. Extract the files in the ZIP file to a location in your HPC filesystem - this is where you will run the scripts from.
2. If you are familiar with git, you can just clone the repo. Doing this in a HPC environment should be straightforward using the following commands to first load git and then clone this repository:
    ```shell
    ml git
    git clone git@github.com:FrancisCrickInstitute/brainsaw-data-processing.git
    ```

### 0.2 FIJI

We're going to use a [FIJI](https://fiji.sc/) plugin called [BigStitcher](https://imagej.net/plugins/bigstitcher/) to the stitching, so you will need to install your own version of FIJI - instructions on how to do so are [here](https://franciscrickinstitute.github.io/Image-Analysis-Group/software_instructions/Fiji/).

### 0.3 BigStitcher

Once FIJI is installed, adding new plugins should be very straightforward - instructions on how to install BigStitcher are [here](https://imagej.net/plugins/bigstitcher/#download).

### 0.4 Set up Python Environment

You may have previously used tools such as [pip](https://pip.pypa.io) or [conda](https://docs.conda.io) to set up and manage Python environments. We now recommened [pixi](https://pixi.prefix.dev/) for these tasks - built on top of tools like pip and conda, it is much, much faster than either. Everything you need to set up the environment with pixi is contained the in the [pixi.toml](./pixi.toml) file in this repo. Use the following commands to set up the necessary python environment on HPC, where `path_to_this_repo` is the folder where you downloaded the files in this repository:
```shell
cd <path_to_this_repo>
ml pixi
pixi install
```
## 1. Convert Files

The raw TIF files from the BrainSaw are currently lacking critical metadata. This will hopefully not be the case in the future, but for now, in order to use BigStitcher, we need to load each of the raw TIF files, add the necessary metadata, and then resave the files. This is all handled automatically by the [submit_ome_convert_jobs.sh](./submit_ome_convert_jobs.sh) script, which you can run as follows:

```
./submit_ome_convert_jobs.sh <input_base_dir> <output_dir>
```

where `input_base_dir` is the path to your raw brainsaw images and `output_dir` is where you want the updated files to be saved.

## 2. Stitch Files

We can now use BigStitcher to stitch and fuse the individual tiles. You can do so by running the [submit_bigstitcher_jobs.sh](./submit_bigstitcher_jobs.sh) script, as follows:
```
./submit_bigstitcher_jobs.sh <input_base_dir> <output_base_dir>
```
where `input_base_dir` is the path to your images to be stitched (the output from step 1 above) and `output_base_dir` is where you want the stitched files to be saved.
