from cv2 import imread, GaussianBlur, imwrite, imshow,waitKey,destroyAllWindows 
from cvlib import detect_face
import os

# read input image
image = imread('/Users/marcelo/Desktop/faceblur/mae.png')

# apply face detection
faces, _ = detect_face(image)

# loop through detected faces
for face in faces:

    (startX,startY) = face[0],face[1]
    (endX,endY) = face[2],face[3]


    # get the subface
    subFace = image[startY:endY,startX:endX]
    # apply gaussian blur over subfaces
    subFace = GaussianBlur(subFace,(23, 23), 30)
    # add the subfaces to de original image
    image[startY:startY+subFace.shape[0], startX:startX+subFace.shape[1]] = subFace

imshow("face_detection", image)

waitKey()

# save output
#cv2.imwrite("face_detection.jpg", image)

# release resources
destroyAllWindows()
