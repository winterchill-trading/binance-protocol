open! Core

type t =
  | Limit
  | Market
  | Other of string
[@@deriving sexp, compare, equal, hash]

let to_wire = function
  | Limit -> "LIMIT"
  | Market -> "MARKET"
  | Other s -> s
;;

let of_wire = function
  | "LIMIT" -> Limit
  | "MARKET" -> Market
  | s -> Other s
;;

let yojson_of_t t : Yojson.Safe.t = `String (to_wire t)

let t_of_yojson (json : Yojson.Safe.t) =
  match json with
  | `String s -> of_wire s
  | _ -> Json.error "Order_type: string expected" json
;;
