type t

val fetch : period:(string * string) -> token:Token.t -> Yojson.Safe.t

val of_json : from:string -> Yojson.Safe.t -> t
(** We pass [from] again here so we can filter out anything that GitHub included by accident. *)

val is_empty : t -> bool

val pp : t Fmt.t
(** [pp] formats as markdown. *)
