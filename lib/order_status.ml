open! Core

type t =
  | New
  | Partially_filled
  | Filled
  | Canceled
  | Expired
  | Expired_in_match
  | Other of string
[@@deriving sexp, compare, equal, hash]

let to_wire = function
  | New -> "NEW"
  | Partially_filled -> "PARTIALLY_FILLED"
  | Filled -> "FILLED"
  | Canceled -> "CANCELED"
  | Expired -> "EXPIRED"
  | Expired_in_match -> "EXPIRED_IN_MATCH"
  | Other s -> s
;;

let of_wire = function
  | "NEW" -> New
  | "PARTIALLY_FILLED" -> Partially_filled
  | "FILLED" -> Filled
  | "CANCELED" -> Canceled
  | "EXPIRED" -> Expired
  | "EXPIRED_IN_MATCH" -> Expired_in_match
  | s -> Other s
;;

let yojson_of_t t : Yojson.Safe.t = `String (to_wire t)

let t_of_yojson (json : Yojson.Safe.t) =
  match json with
  | `String s -> of_wire s
  | _ -> Json.error "Order_status: string expected" json
;;

let is_final = function
  | Filled | Canceled | Expired | Expired_in_match -> true
  | New | Partially_filled | Other _ -> false
;;
