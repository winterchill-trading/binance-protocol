open! Core
open Binance_protocol

let%expect_test "stream names" =
  List.iter
    [ "btcusdt@depth"
    ; "btcusdt@depth@100ms"
    ; "btcusdt@depth5"
    ; "ethusdt@depth20@500ms"
    ; "btcusdt@aggTrade"
    ; "bnbusdt@bookTicker"
    ; "btcusdt@markPrice"
    ; "btcusdt@markPrice@1s"
    ; "btcusdt@depth7"
    ; "btcusdt@depth@1s"
    ; "BTCUSDT@depth"
    ; "!markPrice@arr"
    ; "btcusdt@kline_1m"
    ]
    ~f:(fun s ->
      let t = Stream_name.of_string s in
      print_s [%sexp (t : Stream_name.t)];
      assert (String.equal (Stream_name.to_string t) s));
  print_s
    [%sexp
      (Stream_name.partial_depth (Symbol.of_string "btcusdt") ~levels:15
       : Stream_name.t Or_error.t)];
  [%expect
    {|
    (Diff_depth (symbol BTCUSDT) (speed ()))
    (Diff_depth (symbol BTCUSDT) (speed (Ms_100)))
    (Partial_depth (symbol BTCUSDT) (levels 5) (speed ()))
    (Partial_depth (symbol ETHUSDT) (levels 20) (speed (Ms_500)))
    (Agg_trade BTCUSDT)
    (Book_ticker BNBUSDT)
    (Mark_price (symbol BTCUSDT) (every_second false))
    (Mark_price (symbol BTCUSDT) (every_second true))
    (Other btcusdt@depth7)
    (Other btcusdt@depth@1s)
    (Other BTCUSDT@depth)
    (Other !markPrice@arr)
    (Other btcusdt@kline_1m)
    (Error ("Stream_name: depth levels must be 5, 10 or 20" (levels 15)))
    |}]
;;

let%expect_test "subscribe requests" =
  List.iter
    [ {|{"method": "SUBSCRIBE", "params": ["btcusdt@aggTrade", "btcusdt@depth"], "id": 1}|}
    ; {|{"method": "UNSUBSCRIBE", "params": ["btcusdt@depth"], "id": 312}|}
    ; {|{"method": "LIST_SUBSCRIPTIONS", "id": 3}|}
    ]
    ~f:(Helpers.round_trip (module Subscribe.Request));
  [%expect
    {|
    ((method_ Subscribe)
     (params ((Agg_trade BTCUSDT) (Diff_depth (symbol BTCUSDT) (speed ()))))
     (id 1))
    {"method":"SUBSCRIBE","params":["btcusdt@aggTrade","btcusdt@depth"],"id":1}
    ((method_ Unsubscribe) (params ((Diff_depth (symbol BTCUSDT) (speed ()))))
     (id 312))
    {"method":"UNSUBSCRIBE","params":["btcusdt@depth"],"id":312}
    ((method_ List_subscriptions) (params ()) (id 3))
    {"method":"LIST_SUBSCRIPTIONS","id":3}
    |}]
;;

let%expect_test "subscribe responses" =
  List.iter
    [ {|{"result": null, "id": 1}|}
    ; {|{"result": ["btcusdt@aggTrade"], "id": 3}|}
    ; {|{"code": 0, "msg": "Unknown property"}|}
    ; {|{"code": 2, "msg": "Invalid request: request ID must be an unsigned integer", "id": 7}|}
    ]
    ~f:(fun json ->
      Helpers.round_trip (module Subscribe.Response) json;
      assert (Subscribe.Response.is_response (Yojson.Safe.from_string json)));
  [%expect
    {|
    (Result (result null) (id 1))
    {"result":null,"id":1}
    (Result (result "[\"btcusdt@aggTrade\"]") (id 3))
    {"result":["btcusdt@aggTrade"],"id":3}
    (Error (code 0) (msg "Unknown property") (id ()))
    {"code":0,"msg":"Unknown property"}
    (Error (code 2)
     (msg "Invalid request: request ID must be an unsigned integer") (id (7)))
    {"code":2,"msg":"Invalid request: request ID must be an unsigned integer","id":7}
    |}]
;;

(* UNVERIFIED: the event payloads below are from memory (see the addendum of
   docs/binance-usdm-spec.md); field lists match the changelog. *)
let round_trip = Helpers.round_trip (module Market_event)

let%expect_test "depth update" =
  round_trip
    {|{"e":"depthUpdate","E":1571889248277,"T":1571889248276,"s":"BTCUSDT","U":390497796,"u":390497878,"pu":390497794,
       "b":[["7403.89","0.002"],["7403.90","3.906"]],"a":[["7405.96","3.340"],["7405.97","0.000"]]}|};
  [%expect
    {|
    (Depth_update
     ((event_time 1571889248277) (transaction_time 1571889248276)
      (symbol BTCUSDT) (first_update_id 390497796) (final_update_id 390497878)
      (prev_final_update_id 390497794)
      (bids (((price 7403.89) (qty 0.002)) ((price 7403.9) (qty 3.906))))
      (asks (((price 7405.96) (qty 3.34)) ((price 7405.97) (qty 0))))))
    {"e":"depthUpdate","E":1571889248277,"T":1571889248276,"s":"BTCUSDT","U":390497796,"u":390497878,"pu":390497794,"b":[["7403.89","0.002"],["7403.9","3.906"]],"a":[["7405.96","3.34"],["7405.97","0"]]}
    |}]
;;

let%expect_test "partial depth in the changelog shape" =
  round_trip
    {|{"lastUpdateId":160,"E":1571889248277,"T":1571889248276,"bids":[["0.0024","10"]],"asks":[["0.0026","100"]]}|};
  [%expect
    {|
    (Depth_snapshot
     ((last_update_id 160) (event_time 1571889248277)
      (transaction_time 1571889248276) (bids (((price 0.0024) (qty 10))))
      (asks (((price 0.0026) (qty 100))))))
    {"lastUpdateId":160,"E":1571889248277,"T":1571889248276,"bids":[["0.0024","10"]],"asks":[["0.0026","100"]]}
    |}]
;;

let%expect_test "agg trade" =
  round_trip
    {|{"e":"aggTrade","E":123456789,"s":"BTCUSDT","a":5933014,"p":"0.001","q":"100","f":100,"l":105,"T":123456785,"m":true}|};
  let trade =
    Agg_trade.t_of_yojson
      (Yojson.Safe.from_string
         {|{"e":"aggTrade","E":1,"s":"BTCUSDT","a":1,"p":"1","q":"2","nq":"1.5","f":1,"l":1,"T":1,"m":false}|})
  in
  print_s
    [%sexp (trade.normal_qty : Size.t option), (Agg_trade.taker_side trade : Side.t)];
  [%expect
    {|
    (Agg_trade
     ((event_time 123456789) (symbol BTCUSDT) (agg_trade_id 5933014)
      (price 0.001) (qty 100) (normal_qty ()) (first_trade_id 100)
      (last_trade_id 105) (trade_time 123456785) (buyer_is_maker true)))
    {"e":"aggTrade","E":123456789,"s":"BTCUSDT","a":5933014,"p":"0.001","q":"100","f":100,"l":105,"T":123456785,"m":true}
    ((1.5) Buy)
    |}]
;;

let%expect_test "book ticker" =
  round_trip
    {|{"e":"bookTicker","u":400900217,"E":1568014460893,"T":1568014460891,"s":"BNBUSDT","b":"25.35190000","B":"31.21000000","a":"25.36520000","A":"40.66000000"}|};
  [%expect
    {|
    (Book_ticker
     ((update_id 400900217) (event_time 1568014460893)
      (transaction_time 1568014460891) (symbol BNBUSDT) (bid_price 25.3519)
      (bid_qty 31.21) (ask_price 25.3652) (ask_qty 40.66)))
    {"e":"bookTicker","u":400900217,"E":1568014460893,"T":1568014460891,"s":"BNBUSDT","b":"25.3519","B":"31.21","a":"25.3652","A":"40.66"}
    |}]
;;

let%expect_test "mark price" =
  round_trip
    {|{"e":"markPriceUpdate","E":1562305380000,"s":"BTCUSDT","p":"11794.15000000","i":"11784.62659091","P":"11784.25641265","r":"0.00038167","T":1562306400000}|};
  [%expect
    {|
    (Mark_price_update
     ((event_time 1562305380000) (symbol BTCUSDT) (mark_price 11794.15)
      (index_price (11784.62659091)) (estimated_settle_price (11784.25641265))
      (funding_rate 0.00038167) (next_funding_time 1562306400000)))
    {"e":"markPriceUpdate","E":1562305380000,"s":"BTCUSDT","p":"11794.15","i":"11784.62659091","P":"11784.25641265","r":"0.00038167","T":1562306400000}
    |}]
;;

let%expect_test "unknown events" =
  round_trip {|{"e":"kline","E":1,"s":"BTCUSDT","k":{}}|};
  round_trip {|[{"e":"markPriceUpdate"}]|};
  [%expect
    {|
    (Unknown (event_type (kline))
     (json "{\"e\":\"kline\",\"E\":1,\"s\":\"BTCUSDT\",\"k\":{}}"))
    {"e":"kline","E":1,"s":"BTCUSDT","k":{}}
    (Unknown (event_type ()) (json "[{\"e\":\"markPriceUpdate\"}]"))
    [{"e":"markPriceUpdate"}]
    |}]
;;

let%expect_test "combined wrapper" =
  let module Combined_market = struct
    type t = Market_event.t Combined.t [@@deriving sexp, equal, yojson]
  end
  in
  Helpers.round_trip
    (module Combined_market)
    {|{"stream":"btcusdt@aggTrade","data":{"e":"aggTrade","E":123456789,"s":"BTCUSDT","a":5933014,"p":"0.001","q":"100","f":100,"l":105,"T":123456785,"m":true}}|};
  [%expect
    {|
    ((stream (Agg_trade BTCUSDT))
     (data
      (Agg_trade
       ((event_time 123456789) (symbol BTCUSDT) (agg_trade_id 5933014)
        (price 0.001) (qty 100) (normal_qty ()) (first_trade_id 100)
        (last_trade_id 105) (trade_time 123456785) (buyer_is_maker true)))))
    {"stream":"btcusdt@aggTrade","data":{"e":"aggTrade","E":123456789,"s":"BTCUSDT","a":5933014,"p":"0.001","q":"100","f":100,"l":105,"T":123456785,"m":true}}
    |}]
;;
