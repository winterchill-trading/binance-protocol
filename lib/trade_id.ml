open! Core
include Exchange_core.Trade_id

let yojson_of_t t : Yojson.Safe.t = `Int (to_int t)

let t_of_yojson (json : Yojson.Safe.t) =
  match json with
  | `Int i -> of_int i
  | _ -> Json.error "Trade_id: integer expected" json
;;
