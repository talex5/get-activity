type t = string

val load : string -> (t, [`Msg of string]) result
(** [load path] loads the GitHub token from [path].
    Returns an error if the token isn't found. *)
