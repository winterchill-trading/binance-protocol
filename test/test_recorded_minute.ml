open! Core
open Binance_protocol

(* A trimmed minute of the real BTCUSDT combined streams (aggTrade, bookTicker,
   depth@100ms with one REST snapshot, markPrice@1s), one frame per line as received.
   Every frame must decode without error and survive a re-encoding. *)

let dir = "fixtures/binance-BTCUSDT-2026-10-12T15-05"

let frames file =
  In_channel.read_lines (dir ^/ file) |> List.filter ~f:(Fn.non String.is_empty)
;;

type frame =
  | Response of Subscribe.Response.t
  | Snapshot of Depth.t
  | Event of Market_event.t Combined.t

let decode line =
  Or_error.try_with (fun () ->
    let json = Yojson.Safe.from_string line in
    if Subscribe.Response.is_response json
    then Response (Subscribe.Response.t_of_yojson json)
    else if String.is_prefix line ~prefix:{|{"lastUpdateId"|}
    then Snapshot (Depth.t_of_yojson json)
    else Event (Combined.t_of_yojson Market_event.t_of_yojson json))
;;

let round_trips = function
  | Response r -> Subscribe.Response.(equal r (t_of_yojson (yojson_of_t r)))
  | Snapshot d -> Depth.(equal d (t_of_yojson (yojson_of_t d)))
  | Event e ->
    let encoded =
      Yojson.Safe.to_string (Combined.yojson_of_t Market_event.yojson_of_t e)
    in
    Combined.equal
      Market_event.equal
      e
      (Combined.t_of_yojson Market_event.t_of_yojson (Yojson.Safe.from_string encoded))
;;

let kind = function
  | Response _ -> "response"
  | Snapshot _ -> "snapshot"
  | Event { data = Depth_update _; _ } -> "depthUpdate"
  | Event { data = Agg_trade _; _ } -> "aggTrade"
  | Event { data = Book_ticker _; _ } -> "bookTicker"
  | Event { data = Mark_price_update _; _ } -> "markPriceUpdate"
  | Event { data = Depth_snapshot _; _ } -> "partialDepth"
  | Event { data = Unknown _; _ } -> "unknown"
;;

let%expect_test "every frame decodes" =
  List.iter [ "trades.jsonl"; "bbo.jsonl"; "l2.jsonl"; "funding.jsonl" ] ~f:(fun file ->
    let decoded = List.map (frames file) ~f:decode in
    let ok = List.filter_map decoded ~f:Result.ok in
    let errors = List.length decoded - List.length ok in
    let kinds =
      List.map ok ~f:kind
      |> List.sort_and_group ~compare:String.compare
      |> List.map ~f:(fun group -> List.hd_exn group, List.length group)
    in
    let not_round_tripping = List.count ok ~f:(Fn.non round_trips) in
    print_s
      [%message
        file
          ~frames:(List.length decoded : int)
          (kinds : (string * int) list)
          (errors : int)
          (not_round_tripping : int)]);
  [%expect
    {|
    (trades.jsonl (frames 151) (kinds ((aggTrade 150) (response 1))) (errors 0)
     (not_round_tripping 0))
    (bbo.jsonl (frames 201) (kinds ((bookTicker 200) (response 1))) (errors 0)
     (not_round_tripping 0))
    (l2.jsonl (frames 10) (kinds ((depthUpdate 8) (response 1) (snapshot 1)))
     (errors 0) (not_round_tripping 0))
    (funding.jsonl (frames 60) (kinds ((markPriceUpdate 59) (response 1)))
     (errors 0) (not_round_tripping 0))
    |}]
;;
