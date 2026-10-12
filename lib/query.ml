open! Core

type t = (string * string) list [@@deriving sexp, compare, equal]

let unreserved c = Char.is_alphanum c || String.mem "-_.~" c

let percent_encode s =
  if String.for_all s ~f:unreserved
  then s
  else
    String.concat_map s ~f:(fun c ->
      if unreserved c then String.of_char c else sprintf "%%%02X" (Char.to_int c))
;;

let encode t =
  List.map t ~f:(fun (k, v) -> percent_encode k ^ "=" ^ percent_encode v)
  |> String.concat ~sep:"&"
;;
