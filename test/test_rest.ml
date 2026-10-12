open! Core
open Binance_protocol
open Ppx_yojson_conv_lib.Yojson_conv.Primitives

let%expect_test "exchangeInfo" =
  Helpers.round_trip
    (module Exchange_info)
    {|{
  "exchangeFilters": [""],
  "rateLimits": [
    {"interval": "MINUTE", "intervalNum": 1, "limit": 2400, "rateLimitType": "REQUEST_WEIGHT"}
  ],
  "serverTime": 1565613908500,
  "assets": [
    {"asset": "BTC", "marginAvailable": true, "autoAssetExchange": "-0.10"}
  ],
  "symbols": [
    {
      "symbol": "BLZUSDT",
      "pair": "BLZUSDT",
      "contractType": "PERPETUAL",
      "deliveryDate": 4133404800000,
      "onboardDate": 1598252400000,
      "status": "TRADING",
      "maintMarginPercent": "2.5000",
      "requiredMarginPercent": "5.0000",
      "baseAsset": "BLZ",
      "quoteAsset": "USDT",
      "marginAsset": "USDT",
      "pricePrecision": 5,
      "quantityPrecision": 0,
      "baseAssetPrecision": 8,
      "quotePrecision": 8,
      "underlyingType": "COIN",
      "underlyingSubType": ["STORAGE"],
      "settlePlan": 0,
      "triggerProtect": "0.15",
      "filters": [
        {
          "filterType": "PRICE_FILTER",
          "maxPrice": "300",
          "minPrice": "0.0001",
          "tickSize": "0.0001",
          "maxQty": "10000000",
          "minQty": "1",
          "stepSize": "1",
          "limit": 200,
          "notional": "5.0",
          "multiplierUp": "1.1500",
          "multiplierDown": "0.8500",
          "multiplierDecimal": "4"
        }
      ],
      "orderTypes": ["LIMIT"],
      "timeInForce": ["GTC"],
      "liquidationFee": "0.010000",
      "marketTakeBound": "0.30"
    }
  ],
  "timezone": "UTC"
}|};
  [%expect
    {|
    ((timezone UTC) (server_time 1565613908500)
     (rate_limits
      (((rate_limit_type REQUEST_WEIGHT) (interval MINUTE) (interval_num 1)
        (limit 2400))))
     (assets
      (((asset BTC) (margin_available true) (auto_asset_exchange (-0.1)))))
     (symbols
      (((symbol BLZUSDT) (pair BLZUSDT) (contract_type PERPETUAL)
        (delivery_date 4133404800000) (onboard_date 1598252400000)
        (status TRADING) (base_asset BLZ) (quote_asset USDT) (margin_asset USDT)
        (price_precision 5) (quantity_precision 0) (base_asset_precision 8)
        (quote_precision 8) (underlying_type (COIN))
        (underlying_sub_type (STORAGE)) (trigger_protect (0.15))
        (liquidation_fee (0.01)) (market_take_bound (0.3))
        (filters
         ((Price_filter (min_price 0.0001) (max_price 300) (tick_size 0.0001))))
        (order_types (Limit)) (time_in_force (Gtc))))))
    {"timezone":"UTC","serverTime":1565613908500,"rateLimits":[{"rateLimitType":"REQUEST_WEIGHT","interval":"MINUTE","intervalNum":1,"limit":2400}],"assets":[{"asset":"BTC","marginAvailable":true,"autoAssetExchange":"-0.1"}],"symbols":[{"symbol":"BLZUSDT","pair":"BLZUSDT","contractType":"PERPETUAL","deliveryDate":4133404800000,"onboardDate":1598252400000,"status":"TRADING","baseAsset":"BLZ","quoteAsset":"USDT","marginAsset":"USDT","pricePrecision":5,"quantityPrecision":0,"baseAssetPrecision":8,"quotePrecision":8,"underlyingType":"COIN","underlyingSubType":["STORAGE"],"triggerProtect":"0.15","liquidationFee":"0.01","marketTakeBound":"0.3","filters":[{"filterType":"PRICE_FILTER","minPrice":"0.0001","maxPrice":"300","tickSize":"0.0001"}],"orderTypes":["LIMIT"],"timeInForce":["GTC"]}]}
    |}]
;;

(* UNVERIFIED: filter shapes other than PRICE_FILTER are assumed, see Exchange_info. *)
let%expect_test "exchangeInfo filters and instrument" =
  let filters =
    {|[{"filterType":"PRICE_FILTER","minPrice":"556.80","maxPrice":"4529764","tickSize":"0.10"},
       {"filterType":"LOT_SIZE","stepSize":"0.001","maxQty":"1000","minQty":"0.001"},
       {"filterType":"MARKET_LOT_SIZE","stepSize":"0.001","maxQty":"120","minQty":"0.001"},
       {"filterType":"MAX_NUM_ORDERS","limit":200},
       {"filterType":"MAX_NUM_ALGO_ORDERS","limit":10},
       {"filterType":"MIN_NOTIONAL","notional":"100"},
       {"filterType":"PERCENT_PRICE","multiplierUp":"1.0500","multiplierDown":"0.9500","multiplierDecimal":"4"},
       {"filterType":"POSITION_RISK_CONTROL","positionControlSide":"NONE"}]|}
  in
  let module Filters = struct
    type t = Exchange_info.Filter.t list [@@deriving sexp, equal, yojson]
  end
  in
  Helpers.round_trip (module Filters) filters;
  let info : Exchange_info.Symbol_info.t =
    { symbol = Symbol.of_string "btcusdt"
    ; pair = "BTCUSDT"
    ; contract_type = "PERPETUAL"
    ; delivery_date = Timestamp_ms.of_int 4133404800000
    ; onboard_date = Timestamp_ms.of_int 1569398400000
    ; status = "TRADING"
    ; base_asset = "BTC"
    ; quote_asset = "USDT"
    ; margin_asset = "USDT"
    ; price_precision = 2
    ; quantity_precision = 3
    ; base_asset_precision = 8
    ; quote_precision = 8
    ; underlying_type = None
    ; underlying_sub_type = []
    ; trigger_protect = None
    ; liquidation_fee = None
    ; market_take_bound = None
    ; filters = Filters.t_of_yojson (Yojson.Safe.from_string filters)
    ; order_types = []
    ; time_in_force = []
    }
  in
  print_s
    [%message
      ""
        ~tick_size:(Exchange_info.Symbol_info.tick_size info : Price.t option)
        ~step_size:(Exchange_info.Symbol_info.step_size info : Size.t option)
        ~min_qty:(Exchange_info.Symbol_info.min_qty info : Size.t option)
        ~min_notional:(Exchange_info.Symbol_info.min_notional info : Usd.t option)
        ~instrument:
          (Exchange_info.Symbol_info.to_instrument info ~max_leverage:125
           : Exchange_core.Instrument.t option)];
  [%expect
    {|
    ((Price_filter (min_price 556.8) (max_price 4529764) (tick_size 0.1))
     (Lot_size (min_qty 0.001) (max_qty 1000) (step_size 0.001))
     (Market_lot_size (min_qty 0.001) (max_qty 120) (step_size 0.001))
     (Max_num_orders (limit 200)) (Max_num_algo_orders (limit 10))
     (Min_notional (notional 100))
     (Percent_price (multiplier_up 1.05) (multiplier_down 0.95)
      (multiplier_decimal 4))
     (Other (filter_type POSITION_RISK_CONTROL)
      (json
       "{\"filterType\":\"POSITION_RISK_CONTROL\",\"positionControlSide\":\"NONE\"}")))
    [{"filterType":"PRICE_FILTER","minPrice":"556.8","maxPrice":"4529764","tickSize":"0.1"},{"filterType":"LOT_SIZE","minQty":"0.001","maxQty":"1000","stepSize":"0.001"},{"filterType":"MARKET_LOT_SIZE","minQty":"0.001","maxQty":"120","stepSize":"0.001"},{"filterType":"MAX_NUM_ORDERS","limit":200},{"filterType":"MAX_NUM_ALGO_ORDERS","limit":10},{"filterType":"MIN_NOTIONAL","notional":"100"},{"filterType":"PERCENT_PRICE","multiplierUp":"1.05","multiplierDown":"0.95","multiplierDecimal":"4"},{"filterType":"POSITION_RISK_CONTROL","positionControlSide":"NONE"}]
    ((tick_size (0.1)) (step_size (0.001)) (min_qty (0.001)) (min_notional (100))
     (instrument
      (((symbol BTCUSDT) (size_decimals 3) (price_tick 0.1)
        (max_significant_figures ()) (max_leverage 125)
        (fees ((taker_bps 3.5) (maker_bps 1)))))))
    |}]
;;

let%expect_test "unknown time in force values are dropped" =
  let json =
    {|{"timezone":"UTC","serverTime":1,"rateLimits":[],"symbols":[{"symbol":"BTCUSDT","pair":"BTCUSDT","contractType":"PERPETUAL","deliveryDate":0,"onboardDate":0,"status":"TRADING","baseAsset":"BTC","quoteAsset":"USDT","marginAsset":"USDT","pricePrecision":2,"quantityPrecision":3,"baseAssetPrecision":8,"quotePrecision":8,"filters":[],"orderTypes":["LIMIT","STOP_MARKET"],"timeInForce":["GTC","XYZ","GTX"]}]}|}
  in
  let t = Exchange_info.t_of_yojson (Yojson.Safe.from_string json) in
  List.iter t.symbols ~f:(fun s ->
    print_s
      [%message
        ""
          ~order_types:(s.order_types : Order_type.t list)
          ~time_in_force:(s.time_in_force : Time_in_force.t list)]);
  [%expect {| ((order_types (Limit (Other STOP_MARKET))) (time_in_force (Gtc Gtx))) |}]
;;

let%expect_test "depth" =
  Helpers.round_trip
    (module Depth)
    {|{"lastUpdateId": 1027024, "E": 1589436922972, "T": 1589436922959,
       "bids": [["4.00000000", "431.00000000"]], "asks": [["4.00000200", "12.00000000"]]}|};
  [%expect
    {|
    ((last_update_id 1027024) (event_time 1589436922972)
     (transaction_time 1589436922959) (bids (((price 4) (qty 431))))
     (asks (((price 4.000002) (qty 12)))))
    {"lastUpdateId":1027024,"E":1589436922972,"T":1589436922959,"bids":[["4","431"]],"asks":[["4.000002","12"]]}
    |}]
;;

let%expect_test "bookTicker" =
  Helpers.round_trip
    (module Book_ticker)
    {|{"symbol": "BTCUSDT", "bidPrice": "4.00000000", "bidQty": "431.00000000",
       "askPrice": "4.00000200", "askQty": "9.00000000", "time": 1589437530011}|};
  [%expect
    {|
    ((symbol BTCUSDT) (bid_price 4) (bid_qty 431) (ask_price 4.000002)
     (ask_qty 9) (time 1589437530011))
    {"symbol":"BTCUSDT","bidPrice":"4","bidQty":"431","askPrice":"4.000002","askQty":"9","time":1589437530011}
    |}]
;;

let%expect_test "premiumIndex" =
  Helpers.round_trip
    (module Premium_index)
    {|{"symbol": "BTCUSDT", "markPrice": "11793.63104562", "indexPrice": "11781.80495970",
       "estimatedSettlePrice": "11781.16138815", "lastFundingRate": "0.00038246",
       "interestRate": "0.00010000", "nextFundingTime": 1597392000000, "time": 1597370495002}|};
  [%expect
    {|
    ((symbol BTCUSDT) (mark_price 11793.63104562) (index_price 11781.8049597)
     (estimated_settle_price (11781.16138815)) (last_funding_rate 0.00038246)
     (interest_rate (0.0001)) (next_funding_time 1597392000000)
     (time 1597370495002))
    {"symbol":"BTCUSDT","markPrice":"11793.63104562","indexPrice":"11781.8049597","estimatedSettlePrice":"11781.16138815","lastFundingRate":"0.00038246","interestRate":"0.0001","nextFundingTime":1597392000000,"time":1597370495002}
    |}]
;;
