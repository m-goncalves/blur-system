from face_recognition import face_locations, load_image_file
from PIL import Image, ImageFilter
from boto3 import resource
import os

class FaceBlur:
    def __init__(self, sourceImage, destinationPath):
        self.s3client = resource("s3")
        self.destinationPath = destinationPath
        self.sourceImage = sourceImage
        self.loadSourceImage()

    def loadSourceImage(self):
        try:
            sourceObject = self.s3client.Object("blur-service-bucket", self.sourceImage[1:])
            sourceObject.download_file(self.sourceImage)
            sourceObject.delete()
            self.image = load_image_file(self.sourceImage)
        except FileNotFoundError:
            print(f"file {self.sourceImage} does not exist")
            exit(1)

    def locateFaces(self):
        try:
            self.faceLocations = face_locations(self.image)
        except TypeError:
            print(f"file {self.sourceImage} is not a valid image")
            exit(1)

        return len(self.faceLocations)

    def blurFaces(self):
        for top, right, bottom, left in self.faceLocations:
            faceImage = self.image[top:bottom, left:right]
            faceImage = Image.fromarray(faceImage)
            faceImage = faceImage.filter(ImageFilter.BoxBlur(23))

            self.image[top:bottom, left:right] = faceImage

    def save(self):
        try:
            self.image = Image.fromarray(self.image)
            self.image.save(self.destinationPath)
            self.s3client.Object("blur-service-bucket", self.destinationPath[1:]).upload_file(self.destinationPath)
        except FileNotFoundError:
            print(f"file {self.destinationPath} does not exist")
            exit(1)