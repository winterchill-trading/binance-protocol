open! Core

type t =
  | Mark_price
  | Contract_price
[@@deriving sexp, compare, equal, hash, enumerate]

let to_wire = function
  | Mark_price -> "MARK_PRICE"
  | Contract_price -> "CONTRACT_PRICE"
;;

let of_wire = function
  | "MARK_PRICE" -> Some Mark_price
  | "CONTRACT_PRICE" -> Some Contract_price
  | _ -> None
;;

let yojson_of_t t : Yojson.Safe.t = `String (to_wire t)
let t_of_yojson = Json.enum_of_yojson ~name:"Working_type" ~of_wire
