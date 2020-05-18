let ( / ) = Filename.concat

let or_die = function
  | Ok x -> x
  | Error (`Msg m) ->
    Fmt.epr "%s@." m;
    exit 1

let one_week = 60. *. 60. *. 24. *. 7.

let home =
  match Sys.getenv_opt "HOME" with
  | None -> Fmt.failwith "$HOME is not set!"
  | Some dir -> dir

let ensure_dir_exists ~mode path =
  match Unix.stat path with
  | exception Unix.Unix_error(Unix.ENOENT, _, _) ->
    Unix.mkdir path mode
  | Unix.{ st_kind = S_DIR; _} -> ()
  | _ -> Fmt.failwith "%S is not a directory!" path

let last_fetch_file =
  let dir = home / ".github" in
  ensure_dir_exists ~mode:0o700 dir;
  dir / "get-activity-timestamp"

let mtime path =
  match Unix.stat path with
  | info -> Some info.Unix.st_mtime
  | exception Unix.Unix_error(Unix.ENOENT, _, _) -> None

let set_mtime path time =
  if not (Sys.file_exists path) then
    close_out @@ open_out_gen [Open_append; Open_creat] 0o600 path;
  Unix.utimes path time time

let get_token () =
  Token.load (home / ".github" / "github-activity-token")

(* Run [fn timestamp], where [timestamp] is the last recorded timestamp (if any).
   On success, update the timestamp to the start time. *)
let with_timestamp fn =
  let now = Unix.time () in
  let last_fetch = mtime last_fetch_file in
  fn last_fetch;
  set_mtime last_fetch_file now

let show ~from json =
  let contribs = Contributions.of_json ~from json in
  if Contributions.is_empty contribs then
    Fmt.epr "(no activity found since %s)@." (Contributions.to_8601 from)
  else
    Fmt.pr "@[<v>%a@]@." Contributions.pp contribs

let mode = `Normal

let () =
  match mode with
  | `Normal ->
    with_timestamp (fun last_fetch ->
        let from = Option.value last_fetch ~default:(Unix.time () -. one_week) in
        let token = get_token () |> or_die in
        show ~from @@ Contributions.fetch ~from ~token
      )
  | `Save ->
    with_timestamp (fun last_fetch ->
        let from = Option.value last_fetch ~default:(Unix.time () -. one_week) in
        let token = get_token () |> or_die in
        Contributions.fetch ~from ~token
        |> Yojson.Safe.to_file "activity.json"
      )
  | `Load ->
    (* When testing formatting changes, it is quicker to fetch the data once and then load it again for each test: *)
    let from = mtime last_fetch_file |> Option.value ~default:0.0 in
    show ~from @@ Yojson.Safe.from_file "activity.json"
