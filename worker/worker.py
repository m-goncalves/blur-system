from face_recognition import face_locations, load_image_file
from PIL import Image, ImageFilter
from blur import FaceBlur
from pika import BlockingConnection, ConnectionParameters, URLParameters
import os

destinationFolder = "/blurred-images"

def destinationPath(sourcePath) -> str:
    if not isinstance(sourcePath, str):
        sourcePath = sourcePath.decode("utf-8")
    barIdx = sourcePath.rfind("/")
    if barIdx > 0:
        sourcePath = sourcePath[barIdx+1:]

    return f"{destinationFolder}/{sourcePath}"

def main():

    rabbitmq_user = os.environ.get("RABBITMQ_DEFAULT_USER")
    rabbitmq_pwd = os.environ.get("RABBITMQ_DEFAULT_PASS")
    rabbitmq_host = os.environ.get("RABBITMQ_HOST")
    rabbitmq_port = os.environ.get("RABBITMQ_PORT")
    rabbitmq_queue = os.environ.get("RABBITMQ_QUEUE")
    url = "amqp://%s:%s@%s:%s" %(rabbitmq_user, rabbitmq_pwd, rabbitmq_host, rabbitmq_port)
    params = URLParameters(url)
    connection = BlockingConnection(params)
    channel = connection.channel()
    channel.queue_declare(queue=rabbitmq_queue)

    def callback(ch, method, properties, body):
        if isinstance(body, bytes):
            body = body.decode("utf-8")
        blur = FaceBlur(body, destinationPath(body))
        blur.locateFaces()
        blur.blurFaces()
        blur.save()

    channel.basic_consume(queue=rabbitmq_queue, on_message_callback=callback, auto_ack=True)

    channel.start_consuming()

if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print('Interrupted')
        exit(0)
