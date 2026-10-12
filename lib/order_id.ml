open! Core
include Exchange_core.Order_id

let yojson_of_t t : Yojson.Safe.t =
  let t = to_int64 t in
  match Int64.to_int t with
  | Some i -> `Int i
  | None -> `Intlit (Int64.to_string t)
;;

let t_of_yojson (json : Yojson.Safe.t) =
  match json with
  | `Int i -> of_int i
  | `Intlit s -> of_string s
  | _ -> Json.error "Order_id: integer expected" json
;;
