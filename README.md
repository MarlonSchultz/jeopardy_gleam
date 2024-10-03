# jeopardy_gleam

Further documentation can be found at <https://hexdocs.pm/jeopardy_gleam>.

## Development

The frontend will try top catch a json from an API. For easy mocking use in gamefiles dir.

```sh
go run github.com/eliben/static-server@latest -cors
```
Do not forget the CORS flag, otherwise you will get a network error

```sh
gleam run -m lustre/dev start # run development server
gleam test  # Run the tests
```
