import os
import json
import asyncio
import tornado.web
import tornado.websocket
from gpiozero import Button
from gpiozero.pins.mock import MockFactory
from gpiozero.devices import Device
from signal import pause
import random
from enum import Enum

# remove on a real raspberry, rasperry gpios will be used then
Device.pin_factory = MockFactory()

# Path to the JSON file

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__)) 
QUESTIONS_JSON = os.path.join(SCRIPT_DIR, '../../gamefiles/product_owners_de.json')

clients = []
question_open : bool = False
pressed_buzzer = "none"

# Pin Listeners
button1 = Button(17)  # First button connected to GPIO 17
button2 = Button(18)  # Second button connected to GPIO 18
button3 = Button(27)  # Third button connected to GPIO 27

button1.when_pressed = lambda: gpio_buzzer_handler("red")
button2.when_pressed = lambda: gpio_buzzer_handler("green")
button3.when_pressed = lambda: gpio_buzzer_handler("yellow")


    
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
        return True  # Allow CORS

    def open(self):
        print("WebSocket opened")
        clients.append(self) 

    def on_close(self):
        print("WebSocket closed")
        clients.remove(self) 


    def on_message(self, message):
        global question_open
        global pressed_buzzer
        match message:
            case "Question open":
                question_open = True
            case "Question closed":
                question_open = False
                pressed_buzzer = "none"
        print(f"Received message from client: {message}")
        
    def send_message(self, message):
            for client in clients:
                client.write_message(message) 


def gpio_buzzer_handler(buzzer):
    """Handler for GPIO events."""
    global question_open
    global pressed_buzzer
    
    print(f"current state question: {question_open}, pressed buzzer {pressed_buzzer}, actual: {buzzer}")
    if question_open and pressed_buzzer == "none":
        pressed_buzzer = buzzer
        for client in clients:
            client.write_message(buzzer)

    elif question_open != True:
        print(f"No question open: Buzz by {buzzer}")
    elif pressed_buzzer != "none":
        print(f"question open but already buzzed: Buzz by {buzzer}")
        


async def simulate_button_press(button):
    while True:
        # Randomize the sleep time between presses
        delay_before_press = random.uniform(0.5, 5.0)  # Between 0.5 and 5 seconds
        delay_before_release = random.uniform(0.5, 2.0)  # Between 0.5 and 2 seconds
        
        # Wait before "pressing" the button
        await asyncio.sleep(delay_before_press)
        button.pin.drive_low()  # Simulate pressing the button
        
        # Wait before "releasing" the button
        await asyncio.sleep(delay_before_release)
        button.pin.drive_high()  # Simulate releasing the button
        
def make_app():
    return tornado.web.Application([
        (r"/", MainHandler),
        (r"/questions", ServeQuestionsHandler),
        (r"/websocket", ServeWebsocket),
    ])


async def main():
    app = make_app()
    app.listen(8888)

    await asyncio.gather(
            simulate_button_press(button1),
            simulate_button_press(button2),
            simulate_button_press(button3)
        )
    
    # Keep the program running to allow Tornado and GPIO event handling
    await asyncio.Event().wait()


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("Shutting down server")
