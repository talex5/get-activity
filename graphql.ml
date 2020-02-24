open Lwt.Infix

let graphql_endpoint = Uri.of_string "https://api.github.com/graphql"

let ( / ) a b = Yojson.Safe.Util.member b a

let exec ?variables token query =
  let body =
    `Assoc (
      ("query", `String query) ::
      (match variables with
       | None -> []
       | Some v -> ["variables", `Assoc v])
    )
    |> Yojson.Safe.to_string
    |> Cohttp_lwt.Body.of_string
  in
  let headers = Cohttp.Header.init_with "Authorization" ("bearer " ^ token) in
  Cohttp_lwt_unix.Client.post ~headers ~body graphql_endpoint >>=
  fun (resp, body) ->
  Cohttp_lwt.Body.to_string body >|= fun body ->
  match Cohttp.Response.status resp with
  | `OK ->
    let json = Yojson.Safe.from_string body in
    begin match json / "errors" with
      | `Null -> json
      | _errors ->
        Fmt.failwith "@[<v2>GitHub returned errors: %a@]" (Yojson.Safe.pretty_print ~std:true) json;
    end
  | err -> Fmt.failwith "@[<v2>Error performing GraphQL query on GitHub: %s@,%s@]"
             (Cohttp.Code.string_of_status err)
             body
