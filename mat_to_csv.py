import glob
import os
import scipy.io
import numpy as np

parent_d = "/Volumes/proj-miguel-aliaga-brainsaw/data/delaune_220501_hml_old_young_female_male/rawData/"

list_ = glob.glob(parent_d+'*/tilePositions.mat')

for file_list in list_:
    
    temp = scipy.io.loadmat(list_[file_list])
    positionArray = temp.get('positionArray')

    out_d = os.path.dirname(list_[0])
    np.savetxt(out_d+'tilePositions.csv', positionArray, delimiter=',')
    
    