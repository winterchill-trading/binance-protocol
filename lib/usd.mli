(** Quote and margin amounts (USDT on USD-M): balances, PnL, margin, notional values.
    Re-exported from {!Exchange_core.Usd}; encoded as decimal strings. Balances of other
    margin assets (multi-assets mode) are carried in the same type. *)

open! Core

include module type of struct
  include Exchange_core.Usd
end
