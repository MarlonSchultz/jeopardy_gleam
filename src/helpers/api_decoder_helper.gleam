import gleam/int
import lustre_http

// Gives more insights into lustre_http HttpErrors
pub fn error_to_string(error: lustre_http.HttpError) -> String {
  case error {
    lustre_http.BadUrl(url) -> "Invalid URL: " <> url
    lustre_http.InternalServerError(body) ->
      "Server returned 500 Internal Server Error: " <> body
    lustre_http.JsonError(_) -> "Error decoding the JSON response"
    lustre_http.NetworkError -> "Network error occurred"
    lustre_http.NotFound -> "The server returned 404 Not Found"
    lustre_http.OtherError(code, body) ->
      "HTTP Error " <> int.to_string(code) <> ": " <> body
    lustre_http.Unauthorized -> "The server returned 401 Unauthorized"
  }
}
