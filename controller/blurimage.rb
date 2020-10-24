require 'bunny'

def destinationPath(sourcePath)

    destinationFolder = "/blurred-images"
    
    sourceFile = sourcePath.dup

    if sourceFile.include? "/"
        idx = sourceFile.length - sourceFile.reverse!.index("/")
        sourceFile.reverse!   
    else
        idx = 0
    end
    
    return destinationFolder + "/" + sourcePath[idx..-1]
end

# RabbitMQ initialization
# Defining the connection to the specific host (defined in the go code after "@")
connection = Bunny.new(host: "rabbitmq")
# Starting the connection
connection.start
# Creating the channel to receive messages
channel = connection.create_channel 
# Specifying the desired queue
queue = channel.queue('blur-service')
sourceFile = ""

begin
    # Receives data from rabbitmq when it hat new messages and defines what has to be done
    queue.subscribe(block: true) do |  _delivery_info, _properties, filepath |
        # calling the python programm and passing the arguments it needs: the image to be blurred and where it has to be placed
        output = system "python3", "transformation/blur.py", filepath, destinationPath(filepath)
        # Removing the original
        system("rm -f " + filepath)
    end
rescue
    puts output
ensure
    connection.close()
    #removing original file
end