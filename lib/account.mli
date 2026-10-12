(** Account information from [GET /fapi/v2/account] (also decodes the v3 shape). Fields
    absent from one of the versions are options; v3 positions have no [entryPrice] and
    [leverage], neither version has [liquidationPrice] on positions (use
    {!Position_risk}). *)

open! Core

module Asset : sig
  type t =
    { asset : string
    ; wallet_balance : Usd.t
    ; unrealized_profit : Usd.t
    ; margin_balance : Usd.t
    ; maint_margin : Usd.t option
    ; initial_margin : Usd.t option
    ; position_initial_margin : Usd.t option
    ; open_order_initial_margin : Usd.t option
    ; cross_wallet_balance : Usd.t option
    ; cross_un_pnl : Usd.t option
    ; available_balance : Usd.t
    ; max_withdraw_amount : Usd.t option
    ; margin_available : bool option
    ; update_time : Timestamp_ms.t
    }
  [@@deriving sexp, compare, equal, yojson]
end

module Position : sig
  type t =
    { symbol : Symbol.t
    ; position_side : Position_side.t
    ; position_amt : Size.t (** positive long, negative short *)
    ; entry_price : Price.t option (** v2 only *)
    ; unrealized_profit : Usd.t
    ; leverage : int option (** v2 only, a JSON string *)
    ; liquidation_price : Price.t option
    ; isolated : bool option
    ; initial_margin : Usd.t option
    ; maint_margin : Usd.t option
    ; position_initial_margin : Usd.t option
    ; open_order_initial_margin : Usd.t option
    ; isolated_margin : Usd.t option
    ; isolated_wallet : Usd.t option
    ; notional : Usd.t option
    ; max_notional : Usd.t option
    ; update_time : Timestamp_ms.t
    }
  [@@deriving sexp, compare, equal, yojson]
end

type t =
  { total_wallet_balance : Usd.t
  ; total_unrealized_profit : Usd.t
  ; total_margin_balance : Usd.t
  ; total_initial_margin : Usd.t option
  ; total_maint_margin : Usd.t option
  ; total_position_initial_margin : Usd.t option
  ; total_open_order_initial_margin : Usd.t option
  ; total_cross_wallet_balance : Usd.t option
  ; total_cross_un_pnl : Usd.t option
  ; available_balance : Usd.t
  ; max_withdraw_amount : Usd.t option
  ; can_trade : bool option (** v2 only *)
  ; fee_tier : int option (** v2 only *)
  ; multi_assets_margin : bool option (** v2 only *)
  ; update_time : Timestamp_ms.t option (** v2 only *)
  ; assets : Asset.t list
  ; positions : Position.t list
  }
[@@deriving sexp, compare, equal, yojson]

val find_asset : t -> string -> Asset.t option

(** Positions with a non-zero [positionAmt]. *)
val open_positions : t -> Position.t list
