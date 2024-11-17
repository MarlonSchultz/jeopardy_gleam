import asyncio
import json
import os
import platform
import random
import threading

import tornado.web
import tornado.websocket

# Conditional import of gpiozero
try:
    from gpiozero import Button
except ImportError:
    # Provide a mock Button class if gpiozero is unavailable
    class Button:
        def __init__(self, *args, **kwargs):
            pass

        def when_pressed(self, handler):
            pass


# Constants
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
QUESTIONS_JSON = os.path.join(SCRIPT_DIR, "../../gamefiles/product_owners_de.json")

# Global Variables
clients = []
question_open: bool = False
pressed_buzzer = "none"
IS_RASPBERRY_PI = platform.system() == "Linux" and os.path.exists("/proc/cpuinfo")


# GPIO Handlers
def gpio_buzzer_handler(buzzer_color: str):
    """Handle GPIO button press events."""
    global question_open, pressed_buzzer

    if question_open and pressed_buzzer == "none":
        pressed_buzzer = buzzer_color
        for client in clients:
            client.write_message(buzzer_color)
        print(f"Buzz accepted: {buzzer_color}")
    elif not question_open:
        print(f"Buzz ignored (no question open): {buzzer_color}")
    elif pressed_buzzer != "none":
        print(f"Buzz ignored (already buzzed): {buzzer_color}")


# GPIO Initialization
def setup_gpio():
    """Setup GPIO buttons and assign handlers."""
    if os.environ.get("DISABLE_GPIO") == "1" or not IS_RASPBERRY_PI:
        print("GPIO setup skipped (non-Raspberry Pi system or disabled).")
        return {}

    buttons = {
        "yellow": Button(17, pull_up=False),
        "blue": Button(23, pull_up=False),
        "green": Button(24, pull_up=False),
        "red": Button(25, pull_up=False),
    }

    for color, button in buttons.items():
        button.when_pressed = lambda color=color: gpio_buzzer_handler(color)

    return buttons


# Initialize buttons with the conditional GPIO setup
buttons = setup_gpio()


# Simulate random button presses
def simulate_button_presses():
    """Simulate random button presses every 2 seconds if not on Raspberry Pi."""
    colors = ["yellow", "blue", "green", "red"]
    while True:
        if not IS_RASPBERRY_PI and os.environ.get("DISABLE_GPIO") != "1":
            random_color = random.choice(colors)
            print(f"Simulating button press: {random_color}")
            gpio_buzzer_handler(random_color)
        asyncio.run(asyncio.sleep(2))


# Start button simulation in a separate thread if not on Raspberry Pi
if not IS_RASPBERRY_PI:
    simulation_thread = threading.Thread(target=simulate_button_presses, daemon=True)
    simulation_thread.start()


# Tornado Handlers
class MainHandler(tornado.web.RequestHandler):
    """Main handler for the root URL."""

    def get(self):
        self.write("Hello, world")


class ServeQuestionsHandler(tornado.web.RequestHandler):
    """Handler for serving questions from a JSON file."""

    def set_default_headers(self):
        self.set_header("Access-Control-Allow-Origin", "*")
        self.set_header("Access-Control-Allow-Methods", "GET, OPTIONS")
        self.set_header("Access-Control-Allow-Headers", "Content-Type, Authorization")

    def options(self):
        self.set_status(204)
        self.finish()

    def get(self):
        try:
            if os.path.exists(QUESTIONS_JSON):
                with open(QUESTIONS_JSON, "r") as f:
                    data = json.load(f)
                self.write(json.dumps(data))
            else:
                raise FileNotFoundError("JSON file not found")
        except FileNotFoundError as e:
            self.write_error(404, message=str(e))
            print(f"Error: {e}")
        except json.JSONDecodeError as e:
            self.write_error(500, message=str(e))
            print(f"JSON Error: {e}")
        except Exception as e:
            self.write_error(500, message=str(e))
            print(f"Unexpected Error: {e}")


class ServeWebsocket(tornado.websocket.WebSocketHandler):
    """WebSocket handler for real-time communication."""

    def check_origin(self, origin):
        return True  # Allow CORS

    def open(self):
        print("WebSocket connection opened")
        clients.append(self)

    def on_close(self):
        print("WebSocket connection closed")
        clients.remove(self)

    def on_message(self, message):
        global question_open, pressed_buzzer
        match message:
            case "Question open":
                question_open = True
                print("Question is now open.")
            case "Question closed":
                question_open = False
                pressed_buzzer = "none"
                print("Question is now closed.")
        print(f"Message received: {message}")


# Tornado Application Setup
GAMEFILES_IMAGES_PATH = os.path.abspath("../gamefiles/images")


def make_app():
    """Create and configure the Tornado web application."""
    return tornado.web.Application(
        [
            (r"/", MainHandler),
            (r"/questions", ServeQuestionsHandler),
            (r"/websocket", ServeWebsocket),
            (
                r"/images/(.*)",
                tornado.web.StaticFileHandler,
                {"path": GAMEFILES_IMAGES_PATH},
            ),
        ]
    )


# Main Application Loop
async def main():
    """Main asynchronous loop for Tornado and GPIO handling."""
    app = make_app()
    app.listen(8888)
    print("Server running at http://localhost:8888")
    await asyncio.Event().wait()  # Keep the event loop running


# Entry Point
if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("Shutting down server")
