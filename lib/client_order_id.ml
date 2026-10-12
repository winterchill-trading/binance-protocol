open! Core
include Exchange_core.Client_order_id

let yojson_of_t t : Yojson.Safe.t = `String (to_string t)

let t_of_yojson (json : Yojson.Safe.t) =
  match json with
  | `String s -> of_string s
  | _ -> Json.error "Client_order_id: string expected" json
;;

let valid_char c = Char.is_alphanum c || String.mem ".:/_-" c

let validate s =
  let len = String.length s in
  if Int.(len >= 1 && len <= 36) && String.for_all s ~f:valid_char
  then Ok (of_string s)
  else Or_error.error_s [%message "Client_order_id: invalid" s]
;;

let is_exchange_generated t =
  let s = to_string t in
  List.exists [ "autoclose-"; "adl_autoclose"; "settlement_autoclose-" ] ~f:(fun prefix ->
    String.is_prefix s ~prefix)
;;
