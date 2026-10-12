open! Core

let round_trip (type a) (module M : Binance_protocol.Codec.S with type t = a) s =
  let decoded = M.t_of_yojson (Yojson.Safe.from_string s) in
  print_s (M.sexp_of_t decoded);
  let encoded = Yojson.Safe.to_string (M.yojson_of_t decoded) in
  print_endline encoded;
  let decoded' = M.t_of_yojson (Yojson.Safe.from_string encoded) in
  if not (M.equal decoded decoded')
  then print_s [%message "round trip mismatch" ~_:(M.sexp_of_t decoded' : Sexp.t)]
;;
