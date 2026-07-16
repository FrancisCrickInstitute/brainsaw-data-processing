import argparse
from pathlib import Path

import numpy as np
import scipy.io


def mat_to_csv(mat_path: Path, csv_path: Path):
    data = scipy.io.loadmat(mat_path)
    position_array = data['positionArray']
    np.savetxt(csv_path, position_array, delimiter=',')


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Ensure tilePositions.csv exists in a section directory, "
                     "converting it from tilePositions.mat if necessary")
    parser.add_argument("input_dir", type=Path, help="Section directory containing tilePositions.mat/.csv")
    args = parser.parse_args()

    mat_path = args.input_dir / "tilePositions.mat"
    csv_path = args.input_dir / "tilePositions.csv"

    if csv_path.exists():
        print(f"{csv_path} already exists, skipping conversion")
    elif mat_path.exists():
        print(f"Converting {mat_path} -> {csv_path}")
        mat_to_csv(mat_path, csv_path)
    else:
        raise FileNotFoundError(
            f"Neither {csv_path.name} nor {mat_path.name} found in {args.input_dir}")