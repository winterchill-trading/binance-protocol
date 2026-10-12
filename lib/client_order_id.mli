(** Client order id ([newClientOrderId], [clientOrderId], [c]): the same type as
    {!Exchange_core.Client_order_id}, a JSON string.

    Binance only accepts ids matching [^[\.A-Z\:/a-z0-9_-]{1,36}$] in requests; use
    {!validate} before sending. Decoding does not validate, since the exchange itself
    produces ids such as ["autoclose-..."] for liquidations. *)

open! Core

include module type of struct
  include Exchange_core.Client_order_id
end

val yojson_of_t : t -> Yojson.Safe.t
val t_of_yojson : Yojson.Safe.t -> t

(** [Ok] when the id is 1 to 36 characters from [A-Z a-z 0-9 . : / _ -]. *)
val validate : string -> t Or_error.t

(** Liquidation ([autoclose-]), ADL ([adl_autoclose]) or settlement
    ([settlement_autoclose-]) orders. *)
val is_exchange_generated : t -> bool
