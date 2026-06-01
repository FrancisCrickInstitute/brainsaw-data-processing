# Pipeline for Stitching BrainSaw Images on HPC

## Prerequisites

You'll need to first install the following in order to run the scripts in this repository.

### Download this Repository

There are two different approaches to downloading a git repository:
1. Click the green `Code` dropdown menu above and click `Download ZIP`. Extract the files in the ZIP file to a location in your HPC filesystem - this is where you will run the scripts from.
2. If you are familiar with git, you can just clone the repo. Doing this in a HPC environment should be straightforward using the following commands to first load git and then clone this repository:
    ```shell
    ml git
    git clone git@github.com:FrancisCrickInstitute/brainsaw-data-processing.git
    ```

### FIJI

We're going to use a [FIJI](https://fiji.sc/) plugin called [BigStitcher](https://imagej.net/plugins/bigstitcher/) to the stitching, so you will need to install your own version of FIJI - instructions on how to do so are [here](https://franciscrickinstitute.github.io/Image-Analysis-Group/software_instructions/Fiji/).

### BigStitcher

Once FIJI is installed, adding new plugins should be very straightforward - instructions on how to install BigStitcher are [here](https://imagej.net/plugins/bigstitcher/#download).

### Set up Python Environment

You may have previously used tools such as [pip](https://pip.pypa.io) or [conda](https://docs.conda.io) to set up and manage Python environments. We now recommened [pixi](https://pixi.prefix.dev/) for these tasks - built on top of tools like pip and conda, it is much, much faster than either. Everything you need to set up the environment with pixi is contained the in the [pixi.toml](./pixi.toml) file in this repo. Use the following commands to set up the necessary python environment on HPC, where `path_to_this_repo` is the folder where you downloaded the files in this repository:
```shell
cd <path_to_this_repo>
ml pixi
pixi install
```
