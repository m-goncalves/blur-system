args = ARGV

destinationDir = "blurred_images"
system("mkdir -p " + destinationDir)
# getting the index of the substring "/" from the array
idx = args[0].index("/")
# assigning to the variable "destination" the string "blurred_images", the character "/" and everything that comes after it
destination = destinationDir + "/" + args[0][idx+1..-1]
# calling the python programm and passing the arguments it is able to receive: the image to be blurred and where it has to be placed
system("python transformation/blur.py " + args[0] + " " + destination)
system("rm -f " + args[0])