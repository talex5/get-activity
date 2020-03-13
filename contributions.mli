type t

val fetch : from:float -> token:Token.t -> Yojson.Safe.t

val of_json : from:float -> Yojson.Safe.t -> t
(** We pass [from] again here so we can filter out anything that GitHub included by accident. *)

val is_empty : t -> bool

val to_8601 : float -> string
(** [to_8601 time] is [time] formatted as an ISO 8601 datestamp. *)

val pp : t Fmt.t
(** [pp] formats as markdown. *)
