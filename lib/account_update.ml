open! Core
open Ppx_yojson_conv_lib.Yojson_conv.Primitives

module Reason = struct
  type t =
    | Deposit
    | Withdraw
    | Order
    | Funding_fee
    | Withdraw_reject
    | Adjustment
    | Insurance_clear
    | Admin_deposit
    | Admin_withdraw
    | Margin_transfer
    | Margin_type_change
    | Asset_transfer
    | Options_premium_fee
    | Options_settle_profit
    | Auto_exchange
    | Coin_swap_deposit
    | Coin_swap_withdraw
    | Other of string
  [@@deriving sexp, compare, equal, hash]

  let known =
    [ Deposit, "DEPOSIT"
    ; Withdraw, "WITHDRAW"
    ; Order, "ORDER"
    ; Funding_fee, "FUNDING_FEE"
    ; Withdraw_reject, "WITHDRAW_REJECT"
    ; Adjustment, "ADJUSTMENT"
    ; Insurance_clear, "INSURANCE_CLEAR"
    ; Admin_deposit, "ADMIN_DEPOSIT"
    ; Admin_withdraw, "ADMIN_WITHDRAW"
    ; Margin_transfer, "MARGIN_TRANSFER"
    ; Margin_type_change, "MARGIN_TYPE_CHANGE"
    ; Asset_transfer, "ASSET_TRANSFER"
    ; Options_premium_fee, "OPTIONS_PREMIUM_FEE"
    ; Options_settle_profit, "OPTIONS_SETTLE_PROFIT"
    ; Auto_exchange, "AUTO_EXCHANGE"
    ; Coin_swap_deposit, "COIN_SWAP_DEPOSIT"
    ; Coin_swap_withdraw, "COIN_SWAP_WITHDRAW"
    ]
  ;;

  let to_wire = function
    | Other s -> s
    | t -> List.Assoc.find_exn known t ~equal
  ;;

  let of_wire s =
    match List.find known ~f:(fun (_, w) -> String.equal w s) with
    | Some (t, _) -> t
    | None -> Other s
  ;;

  let yojson_of_t t : Yojson.Safe.t = `String (to_wire t)

  let t_of_yojson (json : Yojson.Safe.t) =
    match json with
    | `String s -> of_wire s
    | _ -> Json.error "Account_update.Reason: string expected" json
  ;;
end

module Balance = struct
  type t =
    { asset : string [@key "a"]
    ; wallet_balance : Usd.t [@key "wb"]
    ; cross_wallet_balance : Usd.t [@key "cw"]
    ; balance_change : Usd.t [@key "bc"]
    }
  [@@deriving sexp, compare, equal, yojson] [@@yojson.allow_extra_fields]
end

(* UNVERIFIED: the reference only confirms that [P] exists; the field names below (s, pa,
   ep, bep, cr, up, mt, iw, ps) are the commonly documented layout. *)
module Position = struct
  type t =
    { symbol : Symbol.t [@key "s"]
    ; position_amt : Size.t [@key "pa"]
    ; entry_price : Price.t [@key "ep"]
    ; breakeven_price : Price.t option
         [@key "bep"] [@default None] [@yojson_drop_if Option.is_none]
    ; accumulated_realized : Usd.t option
         [@key "cr"] [@default None] [@yojson_drop_if Option.is_none]
    ; unrealized_pnl : Usd.t [@key "up"]
    ; margin_type : string option
         [@key "mt"] [@default None] [@yojson_drop_if Option.is_none]
    ; isolated_wallet : Usd.t option
         [@key "iw"] [@default None] [@yojson_drop_if Option.is_none]
    ; position_side : Position_side.t [@key "ps"]
    }
  [@@deriving sexp, compare, equal, yojson] [@@yojson.allow_extra_fields]
end

module Data = struct
  type t =
    { balances : Balance.t list [@key "B"] [@default []]
    ; positions : Position.t list [@key "P"] [@default []]
    ; reason : Reason.t [@key "m"]
    }
  [@@deriving yojson] [@@yojson.allow_extra_fields]
end

module Wire = struct
  type t =
    { event_time : Timestamp_ms.t [@key "E"]
    ; transaction_time : Timestamp_ms.t [@key "T"]
    ; data : Data.t [@key "a"]
    }
  [@@deriving yojson] [@@yojson.allow_extra_fields]
end

type t =
  { event_time : Timestamp_ms.t
  ; transaction_time : Timestamp_ms.t
  ; reason : Reason.t
  ; balances : Balance.t list
  ; positions : Position.t list
  }
[@@deriving sexp, compare, equal]

let event_type = "ACCOUNT_UPDATE"

let yojson_of_t { event_time; transaction_time; reason; balances; positions } =
  Json.with_tag
    (Wire.yojson_of_t
       { event_time; transaction_time; data = { balances; positions; reason } })
    ~key:"e"
    ~value:event_type
;;

let t_of_yojson json =
  let { Wire.event_time; transaction_time; data = { balances; positions; reason } } =
    Wire.t_of_yojson json
  in
  { event_time; transaction_time; reason; balances; positions }
;;
