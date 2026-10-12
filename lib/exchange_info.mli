(** Trading rules from [GET /fapi/v1/exchangeInfo]. Only the fields an order router needs
    are kept; [exchangeFilters], [maintMarginPercent] and the other documented-as-ignore
    fields are dropped. *)

open! Core

module Filter : sig
  (** One entry of [symbols[].filters], tagged by [filterType]. Each object carries only
      the fields of its type. Only the [PRICE_FILTER] shape is verified, see the
      implementation. *)
  type t =
    | Price_filter of
        { min_price : Price.t
        ; max_price : Price.t
        ; tick_size : Price.t
        }
    | Lot_size of
        { min_qty : Size.t
        ; max_qty : Size.t
        ; step_size : Size.t
        }
    | Market_lot_size of
        { min_qty : Size.t
        ; max_qty : Size.t
        ; step_size : Size.t
        }
    | Max_num_orders of { limit : int }
    | Max_num_algo_orders of { limit : int }
    | Min_notional of { notional : Usd.t }
    | Percent_price of
        { multiplier_up : Decimal.t
        ; multiplier_down : Decimal.t
        ; multiplier_decimal : int
        }
    | Other of
        { filter_type : string
        ; json : Json.t
        }
  [@@deriving sexp, compare, equal, yojson]
end

module Rate_limit : sig
  (** [{"rateLimitType": "REQUEST_WEIGHT", "interval": "MINUTE", "intervalNum": 1, "limit": 2400}] *)
  type t =
    { rate_limit_type : string
    ; interval : string
    ; interval_num : int
    ; limit : int
    }
  [@@deriving sexp, compare, equal, yojson]
end

module Asset : sig
  (** Margin asset:
      [{"asset": "BTC", "marginAvailable": true, "autoAssetExchange": "-0.10"}] *)
  type t =
    { asset : string
    ; margin_available : bool
    ; auto_asset_exchange : Decimal.t option
    }
  [@@deriving sexp, compare, equal, yojson]
end

module Symbol_info : sig
  type t =
    { symbol : Symbol.t
    ; pair : string
    ; contract_type : string (** ["PERPETUAL"], ["CURRENT_QUARTER"], ... *)
    ; delivery_date : Timestamp_ms.t
    ; onboard_date : Timestamp_ms.t
    ; status : string (** ["TRADING"], ["SETTLING"], ... *)
    ; base_asset : string
    ; quote_asset : string
    ; margin_asset : string
    ; price_precision : int (** not the tick size; use {!tick_size} *)
    ; quantity_precision : int (** not the step size; use {!step_size} *)
    ; base_asset_precision : int
    ; quote_precision : int
    ; underlying_type : string option
    ; underlying_sub_type : string list
    ; trigger_protect : Decimal.t option
    ; liquidation_fee : Decimal.t option
    ; market_take_bound : Decimal.t option
    ; filters : Filter.t list
    ; order_types : Order_type.t list
    ; time_in_force : Time_in_force.t list
    (** values this library does not know are dropped when decoding *)
    }
  [@@deriving sexp, compare, equal, yojson]

  (** [PRICE_FILTER.tickSize]. *)
  val tick_size : t -> Price.t option

  (** [LOT_SIZE.stepSize]. *)
  val step_size : t -> Size.t option

  (** [LOT_SIZE.minQty]. *)
  val min_qty : t -> Size.t option

  (** [MIN_NOTIONAL.notional]. *)
  val min_notional : t -> Usd.t option

  (** The venue-neutral trading rules: price tick from [PRICE_FILTER], size decimals from
      [LOT_SIZE.stepSize]. [None] unless both filters are present and the step size is a
      power of ten no finer than [10^-8]. Binance does not publish a significant-figure
      limit, and leverage is per account, hence [max_leverage]. *)
  val to_instrument
    :  ?fees:Exchange_core.Fee_schedule.t
    -> t
    -> max_leverage:int
    -> Exchange_core.Instrument.t option
end

type t =
  { timezone : string
  ; server_time : Timestamp_ms.t (** documented as "ignore"; use [GET /fapi/v1/time] *)
  ; rate_limits : Rate_limit.t list
  ; assets : Asset.t list
  ; symbols : Symbol_info.t list
  }
[@@deriving sexp, compare, equal, yojson]

val find_symbol : t -> Symbol.t -> Symbol_info.t option
