val fetch : from:float -> token:Token.t -> Yojson.Safe.t
val pp : from:float -> Yojson.Safe.t Fmt.t
(** [pp ~from json] formats [json] as markdown.
    We pass [from] again here so we can filter out anything that GitHub included by accident. *)
