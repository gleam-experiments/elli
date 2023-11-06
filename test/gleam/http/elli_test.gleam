import gleam/http/elli
import gleam/bytes_builder.{type BytesBuilder}
import gleam/http.{Get, Head, Post}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/hackney

pub fn echo_service(request: Request(BitArray)) -> Response(BytesBuilder) {
  let body = case request.body {
    <<>> -> bytes_builder.from_string("Default body")
    x -> bytes_builder.from_bit_array(x)
  }
  response.new(200)
  |> response.prepend_header("made-with", "Gleam")
  |> response.set_body(body)
}

pub fn request_test() {
  // TODO: Assign these ports on random free ones aviable
  // TODO: Shut down server after test?
  let port = 3078
  let assert Ok(_) = elli.start(echo_service, on_port: port)

  let req =
    request.new()
    |> request.set_method(Get)
    |> request.set_host("0.0.0.0")
    |> request.set_scheme(http.Http)
    |> request.set_port(port)

  let assert Ok(resp) = hackney.send(req)
  let assert 200 = resp.status
  let assert Ok("Gleam") = response.get_header(resp, "made-with")
  let assert "Default body" = resp.body
}

pub fn get_request_does_not_discard_body_test() {
  let port = 3079
  let assert Ok(_) = elli.start(echo_service, on_port: port)

  let req =
    request.new()
    |> request.set_method(Get)
    |> request.set_host("0.0.0.0")
    |> request.set_scheme(http.Http)
    |> request.set_port(port)
    |> request.set_body("This does NOT get dropped")

  let assert Ok(resp) = hackney.send(req)
  let assert 200 = resp.status
  let assert Ok("Gleam") = response.get_header(resp, "made-with")
  let assert "This does NOT get dropped" = resp.body
}

pub fn head_request_discards_body_test() {
  let port = 3080
  let assert Ok(_) = elli.start(echo_service, on_port: port)

  let req =
    request.new()
    |> request.set_method(Head)
    |> request.set_host("0.0.0.0")
    |> request.set_scheme(http.Http)
    |> request.set_port(port)
    |> request.set_body("This gets dropped")

  let assert Ok(resp) = hackney.send(req)
  let assert 200 = resp.status
  let assert Ok("Gleam") = response.get_header(resp, "made-with")
  let assert "" = resp.body
}

pub fn body_is_echoed_on_post_test() {
  let port = 3081
  let assert Ok(_) = elli.start(echo_service, on_port: port)

  let req =
    request.new()
    |> request.set_method(Post)
    |> request.set_host("0.0.0.0")
    |> request.set_scheme(http.Http)
    |> request.set_port(port)
    |> request.set_body("Ping")

  let assert Ok(resp) = hackney.send(req)
  let assert 200 = resp.status
  let assert Ok("Gleam") = response.get_header(resp, "made-with")
  let assert "Ping" = resp.body
}
