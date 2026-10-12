(** Exchange-assigned order id ([orderId], [i]): {!Exchange_core.Order_id}, a JSON
    integer. *)

open! Core

include module type of struct
  include Exchange_core.Order_id
end

val yojson_of_t : t -> Yojson.Safe.t
val t_of_yojson : Yojson.Safe.t -> t
