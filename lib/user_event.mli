(** A user-data stream message, decoded by its ["e"] field. Other events ([MARGIN_CALL],
    [ACCOUNT_CONFIG_UPDATE], [TRADE_LITE], [ALGO_UPDATE], ...) are kept as [Unknown]. *)

open! Core

type t =
  | Order_trade_update of Order_trade_update.t
  | Account_update of Account_update.t
  | Listen_key_expired of Listen_key_expired.t
  | Unknown of
      { event_type : string option
      ; json : Json.t
      }
[@@deriving sexp, compare, equal, yojson]

(** [E]; [None] for [Unknown]. Use it to order events of different types. *)
val event_time : t -> Timestamp_ms.t option
