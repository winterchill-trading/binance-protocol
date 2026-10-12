open! Core
include Order

let to_exchange_core (t : t) : Exchange_core.Open_order.t =
  { symbol = t.symbol
  ; side = t.side
  ; px = t.price
  ; size = remaining_qty t
  ; orig_size = Some t.orig_qty
  ; order_id = t.order_id
  ; client_order_id = Some t.client_order_id
  ; timestamp =
      Time_ns.to_int_ns_since_epoch
        (Timestamp_ms.to_time_ns (Option.value t.time ~default:t.update_time))
  }
;;
