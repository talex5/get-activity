(lang dune 2.3)
(generate_opam_files true)
(source (github talex5/get-activity))
(authors "talex5@gmail.com")
(maintainers "talex5@gmail.com")

(package
 (name get-activity)
 (synopsis "collect activity as markdown")
 (depends
  cohttp-lwt-unix
  yojson))
