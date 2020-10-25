from face_recognition import face_locations, load_image_file
from PIL import Image, ImageFilter
import os

class FaceBlur:
    def _init_(self, sourceImage, destinationPath):
        self.destinationPath = destinationPath
        self.sourceImage = sourceImage
        self.loadSourceImage()

    def loadSourceImage(self):
        try:
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
            os.remove(self.sourceImage)
            self.image = Image.fromarray(self.image)
            self.image.save(self.destinationPath)
        except FileNotFoundError:
            print(f"file {self.destinationPath} does not exist")
            exit(1)