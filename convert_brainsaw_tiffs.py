import argparse
from pathlib import Path

import numpy as np
from bioio import BioImage
from bioio.writers import OmeTiffWriter


def convert_image(input_path: Path, output_path: Path):
    print(f"Opening {input_path}")
    img = BioImage(input_path)
    data = np.asarray(img.data)

    print(f"Shape: {data.shape}, dtype: {data.dtype}")
    print(f"min: {data.min()}, max: {data.max()}, mean: {data.mean():.2f}")

    if data.dtype == np.int16:
        print("Converting int16 → uint16")
        data = data.astype(np.int32) + 1000  # fixed shift: maps [-32768, 32767] → [0, 65535]
        data = data.astype(np.uint16)
        print(f"After conversion - min: {data.min()}, max: {data.max()}")

    print(f"Saving {output_path}")
    OmeTiffWriter.save(data, output_path, dim_order="TCZYX", overwrite=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Convert BrainSaw TIFFs to OME-TIFF format")
    parser.add_argument("input", type=Path, help="Input TIFF file")
    parser.add_argument("output", type=Path, help="Output OME-TIFF file")
    args = parser.parse_args()

    convert_image(args.input, args.output)
