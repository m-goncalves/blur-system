from cvlib import detect_face
from cv2 import GaussianBlur, imread, imwrite, imshow, waitKey, destroyAllWindows
#import cvlib as cv
import os

# readind input image
image = imread('/Users/marcelo/Desktop/imgs/marcelo.jpg')

# applying face detection. returns the coordinates
faces, _  = detect_face(image)

# looping through detected faces
for face in faces:

    #assigning the coordinates to the variables
    startX, startY, endX, endY = face
    #building point to be blurried
    face_image = image[startY:endY, startX:endX]
    #blurring faces
    face_image = GaussianBlur(face_image, (23, 23), 30)
    #rebuilding the image. "shape[0] and height returns nr. of rows and columns"
    # dont understand the logics
    width = face_image.shape[0]
    height = face_image.shape[1]
    image[startY:startY+width, startX:startX+height] = face_image   

imshow("face_detection", image)
waitKey()
