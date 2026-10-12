open! Core

type t =
  | Both
  | Long
  | Short
[@@deriving sexp, compare, equal, hash, enumerate]

let to_wire = function
  | Both -> "BOTH"
  | Long -> "LONG"
  | Short -> "SHORT"
;;

let of_wire = function
  | "BOTH" -> Some Both
  | "LONG" -> Some Long
  | "SHORT" -> Some Short
  | _ -> None
;;

let yojson_of_t t : Yojson.Safe.t = `String (to_wire t)
let t_of_yojson = Json.enum_of_yojson ~name:"Position_side" ~of_wire
