from cvlib import detect_face
from cv2 import blur, imread, imwrite
from argparse import ArgumentParser, ArgumentTypeError
import os

# receiving arguments from the command line
parser = ArgumentParser(description="Blurring faces of images")
parser.add_argument('source_path', metavar="source", type=str, help="Path from the image to be blurred")
parser.add_argument('destination_path', metavar="destination", type=str, help="Path where the blurred image will be written")
args = parser.parse_args()

# reading input image
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
    face_image = blur(face_image, (40, 40))
    #rebuilding the image. "shape[0] and height returns nr. of rows and nr. of columns"
    # dont understand the logics
    width = face_image.shape[0]
    height = face_image.shape[1]
    image[startY:startY+width, startX:startX+height] = face_image   
# writing the blurred image to folder "transformation"
imwrite(args.destination_path, image)
