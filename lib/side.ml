open! Core
include Exchange_core.Side

let to_wire = function
  | Buy -> "BUY"
  | Sell -> "SELL"
;;

let of_wire = function
  | "BUY" -> Some Buy
  | "SELL" -> Some Sell
  | _ -> None
;;

let yojson_of_t t : Yojson.Safe.t = `String (to_wire t)
let t_of_yojson = Json.enum_of_yojson ~name:"Side" ~of_wire
