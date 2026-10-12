open! Core
include Exchange_core.Symbol

let of_string s = Exchange_core.Symbol.of_string (String.uppercase s)

let t_of_sexp = function
  | Sexp.Atom s -> of_string s
  | sexp -> of_sexp_error "Symbol.t_of_sexp: atom expected" sexp
;;

let to_stream_prefix t = String.lowercase (to_string t)
let yojson_of_t t : Yojson.Safe.t = `String (to_string t)

let t_of_yojson (json : Yojson.Safe.t) =
  match json with
  | `String s -> of_string s
  | _ -> Json.error "Symbol: string expected" json
;;
