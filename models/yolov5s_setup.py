import cv2 # opencv-python
from PIL import Image
import numpy as np

image = Image.open("./tmp/zidane.jpg")
image = np.asarray(image)
image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
image = cv2.resize(image, dsize=(640, 640), interpolation=cv2.INTER_CUBIC)
image = np.ascontiguousarray(image, dtype=np.float32) # uint8 to float32
image = np.transpose(image / 255.0, [2, 0, 1])

images = np.array([image])

print(images.shape, images.dtype)

np.savez("./yolov5s.npz", images=images)
