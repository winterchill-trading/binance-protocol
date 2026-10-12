(** Prices (limit, stop, mark, index, entry and liquidation prices). Re-exported from
    {!Exchange_core.Price}; encoded as decimal strings such as ["7819.01"]. *)

open! Core

include module type of struct
  include Exchange_core.Price
end
