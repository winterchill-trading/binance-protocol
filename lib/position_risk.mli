(** An item of [GET /fapi/v2/positionRisk] (also decodes the v3 shape). Version-specific
    fields are options: v2 has [leverage], [marginType], [isAutoAddMargin] and
    [maxNotionalValue]; v3 has [breakEvenPrice], [marginAsset], margins and [adl]. *)

open! Core

type t =
  { symbol : Symbol.t
  ; position_side : Position_side.t
  ; position_amt : Size.t (** positive long, negative short *)
  ; entry_price : Price.t
  ; break_even_price : Price.t option
  ; mark_price : Price.t
  ; unrealized_profit : Usd.t (** [unRealizedProfit] *)
  ; liquidation_price : Price.t (** ["0"] when there is none *)
  ; isolated_margin : Usd.t option
  ; notional : Usd.t option
  ; isolated_wallet : Usd.t option
  ; margin_asset : string option
  ; leverage : int option (** v2 only, a JSON string *)
  ; margin_type : string option (** ["isolated"] or ["cross"], v2 only *)
  ; is_auto_add_margin : bool option (** v2 only, a JSON string *)
  ; max_notional_value : Usd.t option
  ; initial_margin : Usd.t option
  ; maint_margin : Usd.t option
  ; position_initial_margin : Usd.t option
  ; open_order_initial_margin : Usd.t option
  ; adl : int option (** ADL ranking, v3 only *)
  ; update_time : Timestamp_ms.t
  }
[@@deriving sexp, compare, equal, yojson]
