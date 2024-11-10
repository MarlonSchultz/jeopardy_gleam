## Development

The frontend will try top catch a json from an API. For easy mocking use in gamefiles dir. 
Mock via:

```sh
go run github.com/eliben/static-server@latest -cors
```
> Do not forget the CORS flag, otherwise you will get a network error

Or run backend in via:
```sh
poetry run backend/server.py


Then run gleam development server via:

```sh
gleam run -m lustre/dev start # run development server
gleam test  # Run the tests
```
