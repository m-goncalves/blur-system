from cvlib import detect_face
from cv2 import GaussianBlur, imread, imwrite, imshow, waitKey, destroyAllWindows
from argparse import ArgumentParser, ArgumentTypeError
import os

# readind input image
parser = ArgumentParser(description="Blurring faces of images")
parser.add_argument('source_path', metavar="source", type=str, help="Path from the image to be blurred")
parser.add_argument('destination_path', metavar="destination", type=str, help="Path where the image will be saved")
args = parser.parse_args()
image = imread(args.source_path)

# applying face detection. returns the coordinates
faces, _  = detect_face(image)

# looping through detected faces
for face in faces:

    #assigning the coordinates to the variables
    startX, startY, endX, endY = face
    #building point to be blurred
    face_image = image[startY:endY, startX:endX]
    #blurring faces
    face_image = GaussianBlur(face_image, (23, 23), 30)
    #rebuilding the image. "shape[0] and height returns nr. of rows and nr. of columns"
    # dont understand the logics
    width = face_image.shape[0]
    height = face_image.shape[1]
    image[startY:startY+width, startX:startX+height] = face_image   

imwrite(args.destination_path, image)
# '/Users/marcelo/Desktop/imgs/marcelo.jpg'