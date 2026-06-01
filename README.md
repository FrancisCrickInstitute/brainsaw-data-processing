# Pipeline for Stitching BrainSaw Images on HPC

## Prerequisites

You'll need to first install the following in order to run the scripts in this repository.

### FIJI

We're going to use a [FIJI](https://fiji.sc/) plugin called [BigStitcher](https://imagej.net/plugins/bigstitcher/) to the stitching, so you will need to install your own version of FIJI - instructions on how to do so are [here](https://franciscrickinstitute.github.io/Image-Analysis-Group/software_instructions/Fiji/).

### BigStitcher

Once FIJI is installed, adding new plugins should be very straightforward - instructions on how to install BigStitcher are [here](https://imagej.net/plugins/bigstitcher/#download).

### Set up Python Environment

You may have previously used tools such as [pip](https://pip.pypa.io) or [conda](https://docs.conda.io) to set up and manage Python environments. We now recommened [pixi](https://pixi.prefix.dev/) for these tasks - built on top of tools like pip and conda, it is much, much faster than either.
