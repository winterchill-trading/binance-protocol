(** Quantities in units of the base asset ([quantity], [origQty], [executedQty]). Signed
    where Binance uses signed amounts ([positionAmt], [pa]). Re-exported from
    {!Exchange_core.Size}; encoded as decimal strings. *)

open! Core

include module type of struct
  include Exchange_core.Size
end
