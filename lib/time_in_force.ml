open! Core

type t =
  | Gtc
  | Ioc
  | Fok
  | Gtx
  | Gtd
  | Rpi
[@@deriving sexp, compare, equal, hash, enumerate]

let to_wire = function
  | Gtc -> "GTC"
  | Ioc -> "IOC"
  | Fok -> "FOK"
  | Gtx -> "GTX"
  | Gtd -> "GTD"
  | Rpi -> "RPI"
;;

let of_wire = function
  | "GTC" -> Some Gtc
  | "IOC" -> Some Ioc
  | "FOK" -> Some Fok
  | "GTX" -> Some Gtx
  | "GTD" -> Some Gtd
  | "RPI" -> Some Rpi
  | _ -> None
;;

let yojson_of_t t : Yojson.Safe.t = `String (to_wire t)
let t_of_yojson = Json.enum_of_yojson ~name:"Time_in_force" ~of_wire

let of_tif : Exchange_core.Tif.t -> t = function
  | Gtc -> Gtc
  | Ioc -> Ioc
  | Alo -> Gtx
;;

let to_tif : t -> Exchange_core.Tif.t option = function
  | Gtc -> Some Gtc
  | Ioc -> Some Ioc
  | Gtx -> Some Alo
  | Fok | Gtd | Rpi -> None
;;
