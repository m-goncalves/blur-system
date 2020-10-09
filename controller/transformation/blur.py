from cvlib import detect_face
from cv2 import blur, imread, imwrite
from argparse import ArgumentParser, ArgumentTypeError
from re import compile

fileRegex = "^(((\.\.\/[^\/ ])|(\/[^\/ ])|([0-9a-zA-Z]))[\\\/\-\w]*[0-9a-zA-Z]\.)+((png)|(jpeg)|(jpg))$"


def file(arg, pat=compile(fileRegex)):
    if not pat.match(arg):
        raise ArgumentTypeError
    return arg

# receiving arguments from the command line
parser = ArgumentParser(description="Blurring faces of images")
parser.add_argument('source_path', metavar="source", type=file, help="Path from the image to be blurred")
parser.add_argument('destination_path', metavar="destination", type=file, help="Path where the blurred image will be written")

try:
    args = parser.parse_args()
except ArgumentTypeError:
    print(f"source file {args.source_path} or destination path is invalid")
    exit(1)
try:
    # reading input image
    image = imread(args.source_path)
except FileNotFoundError:
    print(f"file {args.source_path} does not exist")
    exit(1)

try:
    # applying face detection. returns the coordinates
    faces, _  = detect_face(image)
except TypeError:
    print(f"file {args.source_path} does not exist or is invalid")
    exit(1)

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

try:
    # writing the blurred image to folder
    imwrite(args.destination_path, image)
except FileNotFoundError:
    print(f"file {args.destination_path} does not exist")
    exit(1)
