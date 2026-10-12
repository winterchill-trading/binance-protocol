open! Core
open Ppx_yojson_conv_lib.Yojson_conv.Primitives

(* UNVERIFIED: the reference only shows a PRICE_FILTER example. The LOT_SIZE,
   MARKET_LOT_SIZE, MIN_NOTIONAL, MAX_NUM_ORDERS, MAX_NUM_ALGO_ORDERS and PERCENT_PRICE
   type names and field layouts follow the common Binance shape. *)
module Filter = struct
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
  [@@deriving sexp, compare, equal]

  module Price_wire = struct
    type t =
      { min_price : Price.t [@key "minPrice"]
      ; max_price : Price.t [@key "maxPrice"]
      ; tick_size : Price.t [@key "tickSize"]
      }
    [@@deriving yojson] [@@yojson.allow_extra_fields]
  end

  module Lot_wire = struct
    type t =
      { min_qty : Size.t [@key "minQty"]
      ; max_qty : Size.t [@key "maxQty"]
      ; step_size : Size.t [@key "stepSize"]
      }
    [@@deriving yojson] [@@yojson.allow_extra_fields]
  end

  module Limit_wire = struct
    type t = { limit : int } [@@deriving yojson] [@@yojson.allow_extra_fields]
  end

  module Notional_wire = struct
    type t = { notional : Usd.t } [@@deriving yojson] [@@yojson.allow_extra_fields]
  end

  module Percent_wire = struct
    type t =
      { multiplier_up : Decimal.t [@key "multiplierUp"]
      ; multiplier_down : Decimal.t [@key "multiplierDown"]
      ; multiplier_decimal : Json.Int_string.t [@key "multiplierDecimal"]
      }
    [@@deriving yojson] [@@yojson.allow_extra_fields]
  end

  let tagged filter_type (json : Yojson.Safe.t) : Yojson.Safe.t =
    match json with
    | `Assoc fields -> `Assoc (("filterType", `String filter_type) :: fields)
    | _ -> json
  ;;

  let yojson_of_t = function
    | Price_filter { min_price; max_price; tick_size } ->
      tagged "PRICE_FILTER" (Price_wire.yojson_of_t { min_price; max_price; tick_size })
    | Lot_size { min_qty; max_qty; step_size } ->
      tagged "LOT_SIZE" (Lot_wire.yojson_of_t { min_qty; max_qty; step_size })
    | Market_lot_size { min_qty; max_qty; step_size } ->
      tagged "MARKET_LOT_SIZE" (Lot_wire.yojson_of_t { min_qty; max_qty; step_size })
    | Max_num_orders { limit } ->
      tagged "MAX_NUM_ORDERS" (Limit_wire.yojson_of_t { limit })
    | Max_num_algo_orders { limit } ->
      tagged "MAX_NUM_ALGO_ORDERS" (Limit_wire.yojson_of_t { limit })
    | Min_notional { notional } ->
      tagged "MIN_NOTIONAL" (Notional_wire.yojson_of_t { notional })
    | Percent_price { multiplier_up; multiplier_down; multiplier_decimal } ->
      tagged
        "PERCENT_PRICE"
        (Percent_wire.yojson_of_t { multiplier_up; multiplier_down; multiplier_decimal })
    | Other { filter_type = _; json } -> json
  ;;

  let t_of_yojson json =
    match Json.tag json ~key:"filterType" with
    | "PRICE_FILTER" ->
      let { Price_wire.min_price; max_price; tick_size } = Price_wire.t_of_yojson json in
      Price_filter { min_price; max_price; tick_size }
    | "LOT_SIZE" ->
      let { Lot_wire.min_qty; max_qty; step_size } = Lot_wire.t_of_yojson json in
      Lot_size { min_qty; max_qty; step_size }
    | "MARKET_LOT_SIZE" ->
      let { Lot_wire.min_qty; max_qty; step_size } = Lot_wire.t_of_yojson json in
      Market_lot_size { min_qty; max_qty; step_size }
    | "MAX_NUM_ORDERS" -> Max_num_orders { limit = (Limit_wire.t_of_yojson json).limit }
    | "MAX_NUM_ALGO_ORDERS" ->
      Max_num_algo_orders { limit = (Limit_wire.t_of_yojson json).limit }
    | "MIN_NOTIONAL" ->
      Min_notional { notional = (Notional_wire.t_of_yojson json).notional }
    | "PERCENT_PRICE" ->
      let { Percent_wire.multiplier_up; multiplier_down; multiplier_decimal } =
        Percent_wire.t_of_yojson json
      in
      Percent_price { multiplier_up; multiplier_down; multiplier_decimal }
    | filter_type -> Other { filter_type; json }
  ;;
end

module Rate_limit = struct
  type t =
    { rate_limit_type : string [@key "rateLimitType"]
    ; interval : string
    ; interval_num : int [@key "intervalNum"]
    ; limit : int
    }
  [@@deriving sexp, compare, equal, yojson] [@@yojson.allow_extra_fields]
end

module Asset = struct
  type t =
    { asset : string
    ; margin_available : bool [@key "marginAvailable"]
    ; auto_asset_exchange : Decimal.t option
         [@key "autoAssetExchange"] [@default None] [@yojson_drop_if Option.is_none]
    }
  [@@deriving sexp, compare, equal, yojson] [@@yojson.allow_extra_fields]
end

(* Decodes known values and drops the rest, so a new value on the exchange does not break
   decoding of the whole symbol list. *)
module Known_tifs = struct
  type t = Time_in_force.t list [@@deriving sexp, compare, equal]

  let yojson_of_t t = [%yojson_of: Time_in_force.t list] t

  let t_of_yojson json =
    [%of_yojson: string list] json |> List.filter_map ~f:Time_in_force.of_wire
  ;;
end

module Symbol_info = struct
  type t =
    { symbol : Symbol.t
    ; pair : string
    ; contract_type : string [@key "contractType"]
    ; delivery_date : Timestamp_ms.t [@key "deliveryDate"]
    ; onboard_date : Timestamp_ms.t [@key "onboardDate"]
    ; status : string
    ; base_asset : string [@key "baseAsset"]
    ; quote_asset : string [@key "quoteAsset"]
    ; margin_asset : string [@key "marginAsset"]
    ; price_precision : int [@key "pricePrecision"]
    ; quantity_precision : int [@key "quantityPrecision"]
    ; base_asset_precision : int [@key "baseAssetPrecision"]
    ; quote_precision : int [@key "quotePrecision"]
    ; underlying_type : string option
         [@key "underlyingType"] [@default None] [@yojson_drop_if Option.is_none]
    ; underlying_sub_type : string list [@key "underlyingSubType"] [@default []]
    ; trigger_protect : Decimal.t option
         [@key "triggerProtect"] [@default None] [@yojson_drop_if Option.is_none]
    ; liquidation_fee : Decimal.t option
         [@key "liquidationFee"] [@default None] [@yojson_drop_if Option.is_none]
    ; market_take_bound : Decimal.t option
         [@key "marketTakeBound"] [@default None] [@yojson_drop_if Option.is_none]
    ; filters : Filter.t list
    ; order_types : Order_type.t list [@key "orderTypes"]
    ; time_in_force : Known_tifs.t [@key "timeInForce"]
    }
  [@@deriving sexp, compare, equal, yojson] [@@yojson.allow_extra_fields]

  let tick_size t =
    List.find_map t.filters ~f:(function
      | Price_filter { tick_size; _ } -> Some tick_size
      | _ -> None)
  ;;

  let lot_size t =
    List.find_map t.filters ~f:(function
      | Lot_size { min_qty; step_size; _ } -> Some (min_qty, step_size)
      | _ -> None)
  ;;

  let step_size t = Option.map (lot_size t) ~f:snd
  let min_qty t = Option.map (lot_size t) ~f:fst

  let min_notional t =
    List.find_map t.filters ~f:(function
      | Min_notional { notional } -> Some notional
      | _ -> None)
  ;;

  let decimals_of_step step =
    List.find
      (List.range 0 (Size.decimals + 1))
      ~f:(fun decimals ->
        Size.equal step (Size.of_units (Int.pow 10 (Size.decimals - decimals))))
  ;;

  let to_instrument ?fees t ~max_leverage =
    let open Option.Let_syntax in
    let%bind price_tick = tick_size t in
    let%bind step = step_size t in
    let%map size_decimals = decimals_of_step step in
    Exchange_core.Instrument.create
      ?fees
      t.symbol
      ~size_decimals
      ~price_tick
      ~max_leverage
  ;;
end

type t =
  { timezone : string
  ; server_time : Timestamp_ms.t [@key "serverTime"]
  ; rate_limits : Rate_limit.t list [@key "rateLimits"]
  ; assets : Asset.t list [@default []]
  ; symbols : Symbol_info.t list
  }
[@@deriving sexp, compare, equal, yojson] [@@yojson.allow_extra_fields]

let find_symbol t symbol =
  List.find t.symbols ~f:(fun (info : Symbol_info.t) -> Symbol.equal info.symbol symbol)
;;
