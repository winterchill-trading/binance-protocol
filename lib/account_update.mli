(** User-data event [ACCOUNT_UPDATE]: balances and positions changed.
    [{"e": "ACCOUNT_UPDATE", "T": 1679974782150, "E": 1679974782155, "a": {"B": [{"a": "USDT", "wb": "685.31478079", "cw": "677.17212454", "bc": "0.00258637"}], "P": [], "m": "ADMIN_DEPOSIT"}}].
    Only changed balances and positions are pushed. The inner [a] object is flattened into
    this record. *)

open! Core

module Reason : sig
  (** [m]: why the account changed. *)
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
  [@@deriving sexp, compare, equal, hash, yojson]

  val to_wire : t -> string
  val of_wire : string -> t
end

module Balance : sig
  type t =
    { asset : string (** [a] *)
    ; wallet_balance : Usd.t (** [wb] *)
    ; cross_wallet_balance : Usd.t (** [cw] *)
    ; balance_change : Usd.t (** [bc]: change excluding PnL and commission *)
    }
  [@@deriving sexp, compare, equal, yojson]
end

module Position : sig
  (** Field names follow the commonly documented layout; see the implementation. *)
  type t =
    { symbol : Symbol.t (** [s] *)
    ; position_amt : Size.t (** [pa] *)
    ; entry_price : Price.t (** [ep] *)
    ; breakeven_price : Price.t option (** [bep] *)
    ; accumulated_realized : Usd.t option (** [cr]: pre-fee *)
    ; unrealized_pnl : Usd.t (** [up] *)
    ; margin_type : string option (** [mt]: ["cross"] or ["isolated"] *)
    ; isolated_wallet : Usd.t option (** [iw] *)
    ; position_side : Position_side.t (** [ps] *)
    }
  [@@deriving sexp, compare, equal, yojson]
end

type t =
  { event_time : Timestamp_ms.t (** [E] *)
  ; transaction_time : Timestamp_ms.t (** [T] *)
  ; reason : Reason.t (** [a.m] *)
  ; balances : Balance.t list (** [a.B] *)
  ; positions : Position.t list (** [a.P] *)
  }
[@@deriving sexp, compare, equal, yojson]

val event_type : string
