(** A market-stream payload, decoded by its ["e"] field. Use it as the [data] of a
    {!Combined.t} on [/stream] connections, or directly on [/ws] connections. *)

open! Core

type t =
  | Depth_update of Depth_update.t (** ["depthUpdate"] *)
  | Agg_trade of Agg_trade.t (** ["aggTrade"] *)
  | Book_ticker of Book_ticker_event.t (** ["bookTicker"] *)
  | Mark_price_update of Mark_price_update.t (** ["markPriceUpdate"] *)
  | Depth_snapshot of Depth.t
  (** an object without ["e"] but with ["lastUpdateId"]: the partial-depth shape listed in
      the changelog, in case partial depth streams do not send ["depthUpdate"] *)
  | Unknown of
      { event_type : string option
      ; json : Json.t
      } (** other events (e.g. [kline], [!markPrice@arr] arrays), kept verbatim *)
[@@deriving sexp, compare, equal, yojson]

val symbol : t -> Symbol.t option
