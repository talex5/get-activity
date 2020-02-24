type t = string

let load path =
  match open_in path with
  | ch ->
    let len = in_channel_length ch in
    let data = really_input_string ch len in
    close_in ch;
    Ok (String.trim data)
  | exception Sys_error e ->
    Fmt.error_msg "Can't open GitHub token file (%s).@,Go to https://github.com/settings/tokens to generate one." e
