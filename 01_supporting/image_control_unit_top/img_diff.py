import sys
import numpy as np
from PIL import Image

img1 = Image.open(sys.argv[1])
img2 = Image.open(sys.argv[2])

img1 = np.array(img1).astype(np.uint8)
img2 = np.array(img2).astype(np.uint8)

img_out = np.abs(img1 - img2)
img_out = np.clip(img_out, 0, 255)

img_out = Image.fromarray(img_out)

img_out.save(sys.argv[3])

