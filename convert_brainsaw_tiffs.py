import argparse
import re
from pathlib import Path

import numpy as np
import pandas as pd
from bioio import BioImage
from bioio.writers import OmeTiffWriter
from ome_types import OME
from ome_types.model import Image, Pixels, Plane, Channel, TiffData
from ome_types.model.simple_types import UnitsLength, PixelType


def parse_filename(path: Path):
    """Extract tile index and z index from filename."""
    match = re.search(r'hml-(\d{4})_(\d{5})\.tif$', path.name)
    if not match:
        raise ValueError(f"Could not parse filename: {path.name}")
    z_index = int(match.group(1))
    tile_index = int(match.group(2))
    return tile_index, z_index


def load_positions(csv_path: Path) -> pd.DataFrame:
    return pd.read_csv(csv_path)


def get_stage_position(positions: pd.DataFrame, tile_index: int, z_index: int,
                       num_z_slices: int, pixel_size_z: float):
    row = positions.iloc[tile_index - 1]
    mm_to_um = 1000
    return (
        float(row['positionArray_3']) * mm_to_um,
        float(-1 * row['positionArray_4']) * mm_to_um,
        float(z_index * num_z_slices * pixel_size_z),
    )


def build_ome_metadata(data: np.ndarray, stage_x: float, stage_y: float, stage_z: float,
                       pixel_size_xy: float, pixel_size_z: float) -> OME:
    t, c, z, y, x = data.shape

    channels = [
        Channel(id=f"Channel:0:{ci}", samples_per_pixel=1)
        for ci in range(c)
    ]

    planes = []
    tiff_data = []
    ifd = 0
    for ti in range(t):
        for ci in range(c):
            for zi in range(z):
                planes.append(Plane(
                    the_t=ti,
                    the_c=ci,
                    the_z=zi,
                    position_x=stage_x,
                    position_y=stage_y,
                    position_z=stage_z + (zi * pixel_size_z),
                    position_x_unit=UnitsLength.MICROMETER,
                    position_y_unit=UnitsLength.MICROMETER,
                    position_z_unit=UnitsLength.MICROMETER,
                ))
                tiff_data.append(TiffData(
                    ifd=ifd,
                    the_t=ti,
                    the_c=ci,
                    the_z=zi,
                    plane_count=1,
                ))
                ifd += 1

    pixels = Pixels(
        dimension_order="XYZCT",
        type=PixelType.UINT16,
        size_x=x, size_y=y, size_z=z, size_c=c, size_t=t,
        physical_size_x=pixel_size_xy,
        physical_size_y=pixel_size_xy,
        physical_size_z=pixel_size_z,
        physical_size_x_unit=UnitsLength.MICROMETER,
        physical_size_y_unit=UnitsLength.MICROMETER,
        physical_size_z_unit=UnitsLength.MICROMETER,
        channels=channels,
        planes=planes,
        tiff_data=tiff_data,
    )

    return OME(images=[Image(pixels=pixels)])


def convert_image(data: np.ndarray, output_path: Path, stage_x: float, stage_y: float,
                  stage_z: float, pixel_size_xy: float, pixel_size_z: float):
    print(f"Shape: {data.shape}, dtype: {data.dtype}")
    print(f"min: {data.min()}, max: {data.max()}, mean: {data.mean():.2f}")

    if data.dtype == np.int16:
        print("Converting int16 → uint16")
        data = data.astype(np.int32) + 1000
        data = data.astype(np.uint16)
        print(f"After conversion - min: {data.min()}, max: {data.max()}")

    ome = build_ome_metadata(data, stage_x, stage_y, stage_z, pixel_size_xy, pixel_size_z)

    print(f"Saving {output_path}")
    OmeTiffWriter.save(data, output_path, dim_order="TCZYX", ome_xml=ome.to_xml(), overwrite=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Convert BrainSaw TIFFs to OME-TIFF format")
    parser.add_argument("input", type=Path, help="Input TIFF file")
    parser.add_argument("output", type=Path, help="Output OME-TIFF file")
    parser.add_argument("positions", type=Path, help="Stage positions CSV file")
    parser.add_argument("--pixel-size-xy", type=float, default=1.0, help="XY pixel size in microns")
    parser.add_argument("--pixel-size-z", type=float, default=1.0, help="Z step size in microns")
    args = parser.parse_args()

    # Parse filename for indices
    tile_index, z_index = parse_filename(args.input)
    print(f"Tile index: {tile_index}, Z index: {z_index}")

    # Load image
    print(f"Opening {args.input}")
    img = BioImage(args.input)
    data = np.asarray(img.data)
    num_z_slices = data.shape[2]  # TCZYX → index 2 is Z

    # Compute stage position
    positions = load_positions(args.positions)
    stage_x, stage_y, stage_z = get_stage_position(positions, tile_index, z_index,
                                                   num_z_slices, args.pixel_size_z)
    print(f"Stage position: X={stage_x}, Y={stage_y}, Z={stage_z}")

    convert_image(data, args.output, stage_x, stage_y, stage_z, args.pixel_size_xy, args.pixel_size_z)
