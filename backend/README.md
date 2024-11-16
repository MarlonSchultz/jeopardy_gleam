## Backend Server for Websocket connection
 Depedencies are managed by poetry

 Use: 
 ```
 poetry shell
 ```

to start a new poetry shell and manage dependencies

## Start server
 Use: 
 ```
 poetry run backend/server.py
 ```
 To start the server

 If you want to turn of GPIO inputs use the environement variable
  ```
 export DISABLE_GPIO=1
  ```