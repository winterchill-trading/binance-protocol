(** Exchange-assigned trade id ([id] in userTrades, [t] in order updates): a JSON integer.
    The same type as {!Exchange_core.Trade_id}. *)

open! Core

include module type of struct
  include Exchange_core.Trade_id
end

val yojson_of_t : t -> Yojson.Safe.t
val t_of_yojson : Yojson.Safe.t -> t
