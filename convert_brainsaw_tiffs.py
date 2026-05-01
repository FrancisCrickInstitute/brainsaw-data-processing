import sys
from pathlib import Path
import numpy as np

from bioio import BioImage
from bioio.writers import OmeTiffWriter


def convert_image(input_path: Path, output_path: Path):
    print(f"Opening {input_path}")

    img = BioImage(input_path)
    data = np.asarray(img.data)

    print(data.shape)
    print(data.ndim)

    # ---- Signed int16 → Unsigned uint16 (bit‑preserving) ----
    data = data.view(np.uint16)
    temp = np.array(np.zeros((1, 2, int(data.shape[2] / 2), data.shape[3], data.shape[4])))
    print(temp.shape)
    print(temp.ndim)
    for z in range(data.shape[2]):
        if z % 2 == 0:
            temp[0, 0, int(z / 2)] = data[0, 0, z]
        else:
            temp[0, 1, int((z - 1) / 2)] = data[0, 0, z]

    data = temp
    print(data.shape)
    print(data.ndim)

    # Enforce expected hyperstack
    t, c, z, y, x = data.shape
    if (c, z, t) != (2, 10, 1):
        raise ValueError(
            f"Unexpected dimensions: Y={y}, X={x}, Z={z}, C={c}, T={t}"
        )

    print(f"Saving {output_path}")

    OmeTiffWriter.save(
        data,
        output_path,
        dim_order="TCZYX",
        overwrite=True,
    )


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python convert_tiff.py INPUT.tif OUTPUT.ome.tif")
        sys.exit(1)

    convert_image(Path(sys.argv[1]), Path(sys.argv[2]))
