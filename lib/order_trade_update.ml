open! Core
open Ppx_yojson_conv_lib.Yojson_conv.Primitives

module Order = struct
  type t =
    { symbol : Symbol.t [@key "s"]
    ; client_order_id : Client_order_id.t [@key "c"]
    ; side : Side.t [@key "S"]
    ; order_type : Order_type.t [@key "o"]
    ; time_in_force : Time_in_force.t [@key "f"]
    ; orig_qty : Size.t [@key "q"]
    ; price : Price.t [@key "p"]
    ; avg_price : Price.t [@key "ap"]
    ; stop_price : Price.t option
         [@key "sp"] [@default None] [@yojson_drop_if Option.is_none]
    ; execution_type : Execution_type.t [@key "x"]
    ; status : Order_status.t [@key "X"]
    ; order_id : Order_id.t [@key "i"]
    ; last_filled_qty : Size.t [@key "l"]
    ; cum_filled_qty : Size.t [@key "z"]
    ; last_filled_price : Price.t [@key "L"]
    ; commission_asset : string option
         [@key "N"] [@default None] [@yojson_drop_if Option.is_none]
    ; commission : Decimal.t option
         [@key "n"] [@default None] [@yojson_drop_if Option.is_none]
    ; trade_time : Timestamp_ms.t [@key "T"]
    ; trade_id : Trade_id.t [@key "t"]
    ; bids_notional : Usd.t option
         [@key "b"] [@default None] [@yojson_drop_if Option.is_none]
    ; asks_notional : Usd.t option
         [@key "a"] [@default None] [@yojson_drop_if Option.is_none]
    ; is_maker : bool [@key "m"]
    ; reduce_only : bool [@key "R"]
    ; working_type : Working_type.t option
         [@key "wt"] [@default None] [@yojson_drop_if Option.is_none]
    ; orig_type : Order_type.t option
         [@key "ot"] [@default None] [@yojson_drop_if Option.is_none]
    ; position_side : Position_side.t option
         [@key "ps"] [@default None] [@yojson_drop_if Option.is_none]
    ; close_position : bool [@key "cp"] [@default false]
    ; activation_price : Price.t option
         [@key "AP"] [@default None] [@yojson_drop_if Option.is_none]
    ; callback_rate : Decimal.t option
         [@key "cr"] [@default None] [@yojson_drop_if Option.is_none]
    ; price_protect : bool [@key "pP"] [@default false]
    ; si : int option [@default None] [@yojson_drop_if Option.is_none]
    ; ss : int option [@default None] [@yojson_drop_if Option.is_none]
    ; realized_profit : Usd.t [@key "rp"]
    ; self_trade_prevention_mode : string option
         [@key "V"] [@default None] [@yojson_drop_if Option.is_none]
    ; price_match : string option
         [@key "pm"] [@default None] [@yojson_drop_if Option.is_none]
    ; good_till_date : Timestamp_ms.t option
         [@key "gtd"] [@default None] [@yojson_drop_if Option.is_none]
    ; expiry_reason : Json.Int_string.t option
         [@key "er"] [@default None] [@yojson_drop_if Option.is_none]
    (* UNVERIFIED: the changelog names [er] with values 0..9 but not its JSON type; both
       strings and integers are accepted, strings are written. *)
    }
  [@@deriving sexp, compare, equal, yojson] [@@yojson.allow_extra_fields]
end

module T = struct
  type t =
    { event_time : Timestamp_ms.t [@key "E"]
    ; transaction_time : Timestamp_ms.t [@key "T"]
    ; order : Order.t [@key "o"]
    }
  [@@deriving sexp, compare, equal, yojson] [@@yojson.allow_extra_fields]
end

include T

let event_type = "ORDER_TRADE_UPDATE"
let yojson_of_t t = Json.with_tag (T.yojson_of_t t) ~key:"e" ~value:event_type
