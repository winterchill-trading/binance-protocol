open! Core

type t =
  | Depth_update of Depth_update.t
  | Agg_trade of Agg_trade.t
  | Book_ticker of Book_ticker_event.t
  | Mark_price_update of Mark_price_update.t
  | Depth_snapshot of Depth.t
  | Unknown of
      { event_type : string option
      ; json : Json.t
      }
[@@deriving sexp, compare, equal]

let yojson_of_t = function
  | Depth_update e -> Depth_update.yojson_of_t e
  | Agg_trade e -> Agg_trade.yojson_of_t e
  | Book_ticker e -> Book_ticker_event.yojson_of_t e
  | Mark_price_update e -> Mark_price_update.yojson_of_t e
  | Depth_snapshot d -> Depth.yojson_of_t d
  | Unknown { event_type = _; json } -> json
;;

let t_of_yojson json =
  match Json.member json ~key:"e" with
  | Some (`String e) when String.equal e Depth_update.event_type ->
    Depth_update (Depth_update.t_of_yojson json)
  | Some (`String e) when String.equal e Agg_trade.event_type ->
    Agg_trade (Agg_trade.t_of_yojson json)
  | Some (`String e) when String.equal e Book_ticker_event.event_type ->
    Book_ticker (Book_ticker_event.t_of_yojson json)
  | Some (`String e) when String.equal e Mark_price_update.event_type ->
    Mark_price_update (Mark_price_update.t_of_yojson json)
  | Some (`String e) -> Unknown { event_type = Some e; json }
  | Some _ -> Unknown { event_type = None; json }
  | None ->
    (match Json.member json ~key:"lastUpdateId" with
     | Some _ -> Depth_snapshot (Depth.t_of_yojson json)
     | None -> Unknown { event_type = None; json })
;;

let symbol = function
  | Depth_update e -> Some e.symbol
  | Agg_trade e -> Some e.symbol
  | Book_ticker e -> Some e.symbol
  | Mark_price_update e -> Some e.symbol
  | Depth_snapshot _ | Unknown _ -> None
;;
