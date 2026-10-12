open! Core

type t =
  | New
  | Canceled
  | Calculated
  | Expired
  | Trade
  | Amendment
  | Other of string
[@@deriving sexp, compare, equal, hash]

let to_wire = function
  | New -> "NEW"
  | Canceled -> "CANCELED"
  | Calculated -> "CALCULATED"
  | Expired -> "EXPIRED"
  | Trade -> "TRADE"
  | Amendment -> "AMENDMENT"
  | Other s -> s
;;

let of_wire = function
  | "NEW" -> New
  | "CANCELED" -> Canceled
  | "CALCULATED" -> Calculated
  | "EXPIRED" -> Expired
  | "TRADE" -> Trade
  | "AMENDMENT" -> Amendment
  | s -> Other s
;;

let yojson_of_t t : Yojson.Safe.t = `String (to_wire t)

let t_of_yojson (json : Yojson.Safe.t) =
  match json with
  | `String s -> of_wire s
  | _ -> Json.error "Execution_type: string expected" json
;;
