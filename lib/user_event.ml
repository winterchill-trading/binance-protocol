open! Core

type t =
  | Order_trade_update of Order_trade_update.t
  | Account_update of Account_update.t
  | Listen_key_expired of Listen_key_expired.t
  | Unknown of
      { event_type : string option
      ; json : Json.t
      }
[@@deriving sexp, compare, equal]

let yojson_of_t = function
  | Order_trade_update e -> Order_trade_update.yojson_of_t e
  | Account_update e -> Account_update.yojson_of_t e
  | Listen_key_expired e -> Listen_key_expired.yojson_of_t e
  | Unknown { event_type = _; json } -> json
;;

let t_of_yojson json =
  match Json.member json ~key:"e" with
  | Some (`String e) when String.equal e Order_trade_update.event_type ->
    Order_trade_update (Order_trade_update.t_of_yojson json)
  | Some (`String e) when String.equal e Account_update.event_type ->
    Account_update (Account_update.t_of_yojson json)
  | Some (`String e) when String.equal e Listen_key_expired.event_type ->
    Listen_key_expired (Listen_key_expired.t_of_yojson json)
  | Some (`String e) -> Unknown { event_type = Some e; json }
  | _ -> Unknown { event_type = None; json }
;;

let event_time = function
  | Order_trade_update e -> Some e.event_time
  | Account_update e -> Some e.event_time
  | Listen_key_expired e -> Some e.event_time
  | Unknown _ -> None
;;
