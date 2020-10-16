from face_recognition import load_image_file, face_locations
from PIL import Image, ImageFilter
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
    image = load_image_file(args.source_path)
except FileNotFoundError:
    print(f"file {args.source_path} does not exist")
    exit(1)

try:
    # applying face detection. returns the coordinates
    faces  = face_locations(image)
except TypeError:
    print(f"file {args.source_path} is not a valid")
    exit(1)

# looping through detected faces
for top, right, bottom, left in faces:

    #assigning the coordinates to the variables
    face_image = image[top:bottom, left:right]
    face_image = Image.fromarray(face_image)
    #blurring faces
    face_image = face_image.filter(ImageFilter.BoxBlur(23))
    #rebuilding the image. "shape[0] and height returns nr. of rows and nr. of columns"
    image[top:bottom, left:right] = face_image  
try:
   
    image = Image.fromarray(image)
     # writing the blurred image to folder
    image.save(args.destination_path)
except FileNotFoundError:
    print(f"file {args.destination_path} does not exist")
    exit(1)
