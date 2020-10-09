args = ARGV

sourceFile = args[0].dup

destinationDir = "blurred_images"

system("mkdir -p " + destinationDir)

if sourceFile.include? "/"
    idx = sourceFile.length - sourceFile.reverse!.index("/")
    sourceFile.reverse!   
else
    idx = 0
end

# assigning to the variable "destination" the string "blurred_images", the character "/" and everything that comes after it
destination = destinationDir + "/" + sourceFile[idx..-1]

# calling the python programm and passing the arguments it needs: the image to be blurred and where it has to be placed
system("python3 transformation/blur.py " + sourceFile + " " + destination)

#removing original file
system("rm -f " + sourceFile)