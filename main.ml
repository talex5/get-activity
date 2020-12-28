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

let to_8601 t =
  let open Unix in
  let t = gmtime t in
  Printf.sprintf "%04d-%02d-%02dT%02d:%02d:%02dZ"
    (t.tm_year + 1900)
    (t.tm_mon + 1)
    (t.tm_mday)
    (t.tm_hour)
    (t.tm_min)
    (t.tm_sec)

(* Run [fn (start, finish)], where [(start, finish)] is the period specified by [period].
   If [period] is [`Since_last_fetch] or [`Last_week] then update the last-fetch timestamp on success. *)
let with_period period fn =
  let now = Unix.time () in
  let last_week = now -. one_week in
  let range =
    match period with
    | `Since_last_fetch ->
      let last_fetch = Option.value ~default:last_week (mtime last_fetch_file) in
      (to_8601 last_fetch, to_8601 now)
    | `Last_week ->
      (to_8601 last_week, to_8601 now)
    | `Range r -> r
  in
  fn range;
  match period with
  | `Since_last_fetch | `Last_week -> set_mtime last_fetch_file now
  | `Range _ -> ()

let show ~from json =
  let contribs = Contributions.of_json ~from json in
  if Contributions.is_empty contribs then
    Fmt.epr "(no activity found since %s)@." from
  else
    Fmt.pr "@[<v>%a@]@." Contributions.pp contribs

let mode = `Normal

open Cmdliner

let from =
  let doc =
    Arg.info ~docv:"TIMESTAMP" ~doc:"Starting date (ISO8601)." [ "from" ]
  in
  Arg.(value & opt (some string) None & doc)

let to_ =
  let doc = Arg.info ~docv:"TIMESTAMP" ~doc:"Ending date (ISO8601)." [ "to" ] in
  Arg.(value & opt (some string) None & doc)

let last_week =
  let doc = Arg.info ~doc:"Show activity from last week" [ "last-week" ] in
  Arg.(value & flag doc)

let period =
  let f from to_ last_week =
    if last_week then `Last_week
    else
      match (from, to_) with
      | None, None -> `Since_last_fetch
      | Some x, Some y -> `Range (x, y)
      | _ -> Fmt.invalid_arg "--to and --from should be provided together"
  in
  Term.(pure f $ from $ to_ $ last_week)

let info = Term.info "get-activity"

let run period : unit =
  match mode with
  | `Normal ->
    with_period period (fun period ->
        (* Fmt.pr "period: %a@." Fmt.(pair string string) period; *)
        let token = get_token () |> or_die in
        show ~from:(fst period) @@ Contributions.fetch ~period ~token
      )
  | `Save ->
    with_period period (fun period ->
        let token = get_token () |> or_die in
        Contributions.fetch ~period ~token
        |> Yojson.Safe.to_file "activity.json"
      )
  | `Load ->
    (* When testing formatting changes, it is quicker to fetch the data once and then load it again for each test: *)
    let from = mtime last_fetch_file |> Option.value ~default:0.0 |> to_8601 in
    show ~from @@ Yojson.Safe.from_file "activity.json"

let () = Term.exit @@ Term.eval (Term.(pure run $ period), info)
