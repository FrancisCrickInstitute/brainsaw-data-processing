
from pathlib import Path
import numpy as np
from bioio import BioImage

input_dir = Path("/nemo/project/proj-miguel-aliaga-brainsaw/data/rawData/CrickSaw_260326_hml_old_young_females_hml-0001")

global_min = np.inf

for f in sorted(input_dir.glob("*.tif")):
    img = BioImage(f)
    data = np.asarray(img.data)
    file_min = data.min()
    print(f"{f.name}: min={file_min}")
    if file_min < global_min:
        global_min = file_min

print(f"\nGlobal minimum across all tiles: {global_min}")