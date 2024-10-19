import os
import json
import asyncio
import tornado.web
import tornado.websocket
import RPi.GPIO as GPIO

# Setup GPIO
GPIO.setmode(GPIO.BCM)  # BCM pin numbering
INPUT_PIN = 17  # Example GPIO pin number
GPIO.setup(INPUT_PIN, GPIO.IN, pull_up_down=GPIO.PUD_UP)  # Set up the GPIO pin as input

# Path to the JSON file
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__)) 
QUESTIONS_JSON = os.path.join(SCRIPT_DIR, '../../gamefiles/answers.json')

# Store WebSocket connections to broadcast messages
clients = []

class MainHandler(tornado.web.RequestHandler):
    def get(self):
        self.write("Hello, world")


class ServeQuestionsHandler(tornado.web.RequestHandler):
    def set_default_headers(self):
        # Allow CORS
        self.set_header("Access-Control-Allow-Origin", "*")
        self.set_header("Access-Control-Allow-Methods", "GET, OPTIONS")
        self.set_header("Access-Control-Allow-Headers", "Content-Type, Authorization")

    def options(self):
        self.set_status(204)
        self.finish()

    def get(self):
        try:
            if os.path.exists(QUESTIONS_JSON):
                with open(QUESTIONS_JSON, 'r') as f:
                    data = json.load(f)
                self.write(json.dumps(data))
            else:
                raise FileNotFoundError("JSON file not found")
        
        except FileNotFoundError as fnf_error:
            error_message = {"error": "File not found", "details": str(fnf_error)}
            self.write(json.dumps(error_message))
            print(fnf_error)
        
        except json.JSONDecodeError as json_error:
            error_message = {"error": "Error parsing JSON", "details": str(json_error)}
            self.write(json.dumps(error_message))
            print(json_error)
        
        except Exception as general_error:
            error_message = {"error": "An unexpected error occurred", "details": str(general_error)}
            self.write(json.dumps(error_message))
            print(general_error)


class ServeWebsocket(tornado.websocket.WebSocketHandler):
    def check_origin(self, origin):
        return True  # Allow CORS!!!!!

    def open(self):
        print("WebSocket opened")
        clients.append(self) 

    def on_close(self):
        print("WebSocket closed")
        clients.remove(self) 

    def on_message(self, message):
        print(f"Received message from client: {message}")
        
    def send_message(self, message):
        for client in clients:
            client.write_message(message) 


def gpio_event_handler(channel):
    """Handler for GPIO events."""
    print(f"GPIO event detected on pin {channel}")
    # Broadcast the event to all connected WebSocket clients
    for client in clients:
        client.write_message(f"GPIO event on pin {channel}")


# Set up GPIO event detection
GPIO.add_event_detect(INPUT_PIN, GPIO.FALLING, callback=gpio_event_handler, bouncetime=200)

def make_app():
    return tornado.web.Application([
        (r"/", MainHandler),
        (r"/questions", ServeQuestionsHandler),
        (r"/websocket", ServeWebsocket),
    ])


async def main():
    app = make_app()
    app.listen(8888)
    print("Server started at ws://localhost:8888/websocket")
    await asyncio.Event().wait()


if __name__ == "__main__":
    try:
        asyncio.run(main())
    finally:
        GPIO.cleanup()  # Ensure GPIO is cleaned up when the script exits
