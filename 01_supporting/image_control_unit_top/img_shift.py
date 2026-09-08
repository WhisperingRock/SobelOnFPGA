import sys
import numpy as np
from PIL import Image

img1 = Image.open(sys.argv[1])

img1 = np.array(img1).astype(np.uint8)

img_out = Image.fromarray(img_out)

img_out.save(sys.argv[2])

