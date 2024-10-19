import asyncio
import tornado.web
import tornado.websocket
import json
import os

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__)) 
QUESTIONS_JSON = os.path.join(SCRIPT_DIR, '../../gamefiles/answers.json')

class MainHandler(tornado.web.RequestHandler):
    def get(self):
        self.write("Hello, world")

class ServeQuestionsWebSocket(tornado.websocket.WebSocketHandler):
    def check_origin(self, origin):
        return True  # ALLOW CORS!!!!!!!!
    
    def open(self):
        print("WebSocket opened")
        try:
            if os.path.exists(QUESTIONS_JSON):
                with open(QUESTIONS_JSON, 'r') as f:
                    data = json.load(f)
                self.write_message(json.dumps(data))
            else:
                raise FileNotFoundError("JSON file not found")
        
        except FileNotFoundError as fnf_error:
            error_message = {"error": "File not found", "details": str(fnf_error)}
            self.write_message(json.dumps(error_message))
            print(fnf_error)
        
        except json.JSONDecodeError as json_error:
            error_message = {"error": "Error parsing JSON", "details": str(json_error)}
            self.write_message(json.dumps(error_message))
            print(json_error)
        
        except Exception as general_error:
            error_message = {"error": "An unexpected error occurred", "details": str(general_error)}
            self.write_message(json.dumps(error_message))
            print(general_error)

    def on_message(self, message):
        # Optional: handle messages received from the client
        print(f"Received message from client: {message}")

    def on_close(self):
        print("WebSocket closed")

def make_app():
    return tornado.web.Application([
        (r"/", MainHandler),
        (r"/questions", ServeQuestionsWebSocket), 
    ])

async def main():
    app = make_app()
    app.listen(8888)
    print("Tornado WebSocket server is running on ws://localhost:8888/questions")
    await asyncio.Event().wait()

if __name__ == "__main__":
    asyncio.run(main())
