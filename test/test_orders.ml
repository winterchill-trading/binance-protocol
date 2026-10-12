open! Core
open Binance_protocol
open Ppx_yojson_conv_lib.Yojson_conv.Primitives

let new_order_response =
  {|{"clientOrderId": "testOrder", "cumQty": "0", "executedQty": "0", "orderId": 22542179,
     "origQty": "10", "price": "0", "reduceOnly": false, "side": "SELL", "positionSide": "SHORT",
     "status": "NEW", "stopPrice": "0", "closePosition": false, "symbol": "BTCUSDT",
     "timeInForce": "GTD", "type": "LIMIT", "origType": "LIMIT", "updateTime": 1566818724722,
     "workingType": "CONTRACT_PRICE", "priceProtect": false, "priceMatch": "NONE",
     "selfTradePreventionMode": "EXPIRE_MAKER", "goodTillDate": 1693207680000}|}
;;

let%expect_test "new order request parameters" =
  let limit =
    New_order.Request.limit
      (Symbol.of_string "BTCUSDT")
      Buy
      ~price:(Price.of_string "9000")
      ~quantity:(Size.of_string "1")
  in
  print_s [%sexp (New_order.Request.to_params limit : (string * string) list)];
  let market =
    New_order.Request.of_order_request
      (Exchange_core.Order_request.market
         ~reduce_only:true
         ~client_order_id:(Exchange_core.Client_order_id.of_string "mm-1")
         (Exchange_core.Symbol.of_string "ETHUSDT")
         Sell
         ~size:(Size.of_string "0.5"))
  in
  print_s [%sexp (New_order.Request.to_params market : (string * string) list)];
  let post_only =
    New_order.Request.of_order_request
      (Exchange_core.Order_request.limit
         ~tif:Alo
         (Exchange_core.Symbol.of_string "ETHUSDT")
         Buy
         ~px:(Price.of_string "2500.5")
         ~size:(Size.of_string "0.01"))
  in
  print_s [%sexp (New_order.Request.to_params post_only : (string * string) list)];
  Helpers.round_trip
    (module New_order.Request)
    (Yojson.Safe.to_string (New_order.Request.yojson_of_t market));
  [%expect
    {|
    ((symbol BTCUSDT) (side BUY) (type LIMIT) (timeInForce GTC) (quantity 1)
     (price 9000))
    ((symbol ETHUSDT) (side SELL) (type MARKET) (quantity 0.5) (reduceOnly true)
     (newClientOrderId mm-1))
    ((symbol ETHUSDT) (side BUY) (type LIMIT) (timeInForce GTX) (quantity 0.01)
     (price 2500.5))
    ((symbol ETHUSDT) (side Sell) (position_side ()) (order_type Market)
     (time_in_force ()) (quantity (0.5)) (price ()) (reduce_only (true))
     (new_client_order_id (mm-1)) (new_order_resp_type ()) (good_till_date ()))
    {"symbol":"ETHUSDT","side":"SELL","type":"MARKET","quantity":"0.5","reduceOnly":"true","newClientOrderId":"mm-1"}
    |}]
;;

let%expect_test "new order response" =
  Helpers.round_trip (module New_order.Response) new_order_response;
  [%expect
    {|
    ((order_id 22542179) (symbol BTCUSDT) (client_order_id testOrder) (side Sell)
     (position_side (Short)) (status New) (order_type Limit) (orig_type (Limit))
     (time_in_force Gtd) (price 0) (orig_qty 10) (executed_qty 0) (cum_qty (0))
     (cum_quote ()) (avg_price ()) (stop_price (0)) (activate_price ())
     (price_rate ()) (reduce_only false) (close_position false)
     (price_protect false) (working_type (Contract_price)) (price_match (NONE))
     (self_trade_prevention_mode (EXPIRE_MAKER)) (good_till_date (1693207680000))
     (time ()) (update_time 1566818724722))
    {"orderId":22542179,"symbol":"BTCUSDT","clientOrderId":"testOrder","side":"SELL","positionSide":"SHORT","status":"NEW","type":"LIMIT","origType":"LIMIT","timeInForce":"GTD","price":"0","origQty":"10","executedQty":"0","cumQty":"0","stopPrice":"0","reduceOnly":false,"closePosition":false,"priceProtect":false,"workingType":"CONTRACT_PRICE","priceMatch":"NONE","selfTradePreventionMode":"EXPIRE_MAKER","goodTillDate":1693207680000,"updateTime":1566818724722}
    |}]
;;

let%expect_test "batch orders" =
  let orders =
    List.init 2 ~f:(fun i ->
      New_order.Request.limit
        ~time_in_force:Gtx
        (Symbol.of_string "BTCUSDT")
        Buy
        ~price:(Price.of_int (100 + i))
        ~quantity:(Size.of_string "0.001"))
  in
  let request = Batch_orders.Request.create orders |> Or_error.ok_exn in
  print_s [%sexp (Batch_orders.Request.to_params request : (string * string) list)];
  print_s
    [%sexp
      (Batch_orders.Request.create (List.init 6 ~f:(fun _ -> List.hd_exn orders))
       : Batch_orders.Request.t Or_error.t)];
  Helpers.round_trip
    (module Batch_orders.Response)
    (sprintf
       {|[%s, {"code": -2022, "msg": "ReduceOnly Order is rejected."}]|}
       new_order_response);
  [%expect
    {|
    ((batchOrders
      "[{\"symbol\":\"BTCUSDT\",\"side\":\"BUY\",\"type\":\"LIMIT\",\"timeInForce\":\"GTX\",\"quantity\":\"0.001\",\"price\":\"100\"},{\"symbol\":\"BTCUSDT\",\"side\":\"BUY\",\"type\":\"LIMIT\",\"timeInForce\":\"GTX\",\"quantity\":\"0.001\",\"price\":\"101\"}]"))
    (Error ("Batch_orders: 1 to 5 orders required" (n 6)))
    ((Ok
      ((order_id 22542179) (symbol BTCUSDT) (client_order_id testOrder)
       (side Sell) (position_side (Short)) (status New) (order_type Limit)
       (orig_type (Limit)) (time_in_force Gtd) (price 0) (orig_qty 10)
       (executed_qty 0) (cum_qty (0)) (cum_quote ()) (avg_price ())
       (stop_price (0)) (activate_price ()) (price_rate ()) (reduce_only false)
       (close_position false) (price_protect false)
       (working_type (Contract_price)) (price_match (NONE))
       (self_trade_prevention_mode (EXPIRE_MAKER))
       (good_till_date (1693207680000)) (time ()) (update_time 1566818724722)))
     (Error ((code Reduce_only_reject) (msg "ReduceOnly Order is rejected."))))
    [{"orderId":22542179,"symbol":"BTCUSDT","clientOrderId":"testOrder","side":"SELL","positionSide":"SHORT","status":"NEW","type":"LIMIT","origType":"LIMIT","timeInForce":"GTD","price":"0","origQty":"10","executedQty":"0","cumQty":"0","stopPrice":"0","reduceOnly":false,"closePosition":false,"priceProtect":false,"workingType":"CONTRACT_PRICE","priceMatch":"NONE","selfTradePreventionMode":"EXPIRE_MAKER","goodTillDate":1693207680000,"updateTime":1566818724722},{"code":-2022,"msg":"ReduceOnly Order is rejected."}]
    |}]
;;

let%expect_test "cancel order" =
  let symbol = Symbol.of_string "BTCUSDT" in
  List.iter
    [ Cancel_order.Request.Target.Order_id (Order_id.of_int 283194212)
    ; Client_order_id (Client_order_id.of_string "myOrder1")
    ]
    ~f:(fun target ->
      print_s
        [%sexp
          (Cancel_order.Request.to_params { symbol; target } : (string * string) list)]);
  Helpers.round_trip
    (module Cancel_order.Response)
    {|{"clientOrderId": "myOrder1", "cumQty": "0", "executedQty": "0", "orderId": 283194212,
       "origQty": "11", "price": "0", "reduceOnly": false, "side": "BUY", "positionSide": "SHORT",
       "status": "CANCELED", "stopPrice": "9300", "closePosition": false, "symbol": "BTCUSDT",
       "timeInForce": "GTC", "origType": "TRAILING_STOP_MARKET", "type": "TRAILING_STOP_MARKET",
       "activatePrice": "9020", "priceRate": "0.3", "updateTime": 1571110484038,
       "workingType": "CONTRACT_PRICE", "priceProtect": false, "priceMatch": "NONE",
       "selfTradePreventionMode": "EXPIRE_MAKER", "goodTillDate": 0}|};
  [%expect
    {|
    ((symbol BTCUSDT) (orderId 283194212))
    ((symbol BTCUSDT) (origClientOrderId myOrder1))
    ((order_id 283194212) (symbol BTCUSDT) (client_order_id myOrder1) (side Buy)
     (position_side (Short)) (status Canceled)
     (order_type (Other TRAILING_STOP_MARKET))
     (orig_type ((Other TRAILING_STOP_MARKET))) (time_in_force Gtc) (price 0)
     (orig_qty 11) (executed_qty 0) (cum_qty (0)) (cum_quote ()) (avg_price ())
     (stop_price (9300)) (activate_price (9020)) (price_rate (0.3))
     (reduce_only false) (close_position false) (price_protect false)
     (working_type (Contract_price)) (price_match (NONE))
     (self_trade_prevention_mode (EXPIRE_MAKER)) (good_till_date (0)) (time ())
     (update_time 1571110484038))
    {"orderId":283194212,"symbol":"BTCUSDT","clientOrderId":"myOrder1","side":"BUY","positionSide":"SHORT","status":"CANCELED","type":"TRAILING_STOP_MARKET","origType":"TRAILING_STOP_MARKET","timeInForce":"GTC","price":"0","origQty":"11","executedQty":"0","cumQty":"0","stopPrice":"9300","activatePrice":"9020","priceRate":"0.3","reduceOnly":false,"closePosition":false,"priceProtect":false,"workingType":"CONTRACT_PRICE","priceMatch":"NONE","selfTradePreventionMode":"EXPIRE_MAKER","goodTillDate":0,"updateTime":1571110484038}
    |}]
;;

let%expect_test "cancel all" =
  print_s
    [%sexp
      (Cancel_all.Request.to_params { symbol = Symbol.of_string "btcusdt" }
       : (string * string) list)];
  Helpers.round_trip
    (module Cancel_all.Response)
    {|{"code": 200, "msg": "The operation of cancel all open order is done."}|};
  [%expect
    {|
    ((symbol BTCUSDT))
    ((code 200) (msg "The operation of cancel all open order is done."))
    {"code":200,"msg":"The operation of cancel all open order is done."}
    |}]
;;

let%expect_test "open orders" =
  let json =
    {|{"avgPrice": "0.00000", "clientOrderId": "abc", "cumQuote": "0", "executedQty": "0",
       "orderId": 1917641, "origQty": "0.40", "origType": "TRAILING_STOP_MARKET", "price": "0",
       "reduceOnly": false, "side": "BUY", "positionSide": "SHORT", "status": "NEW",
       "stopPrice": "9300", "closePosition": false, "symbol": "BTCUSDT", "time": 1579276756075,
       "timeInForce": "GTC", "type": "TRAILING_STOP_MARKET", "activatePrice": "9020",
       "priceRate": "0.3", "updateTime": 1579276756075, "workingType": "CONTRACT_PRICE",
       "priceProtect": false, "priceMatch": "NONE", "selfTradePreventionMode": "EXPIRE_MAKER",
       "goodTillDate": 0}|}
  in
  let module Open_orders = struct
    type t = Open_order.t list [@@deriving sexp, equal, yojson]
  end
  in
  Helpers.round_trip (module Open_orders) (sprintf "[%s]" json);
  print_s
    [%sexp
      (Open_order.to_exchange_core (Open_order.t_of_yojson (Yojson.Safe.from_string json))
       : Exchange_core.Open_order.t)];
  [%expect
    {|
    (((order_id 1917641) (symbol BTCUSDT) (client_order_id abc) (side Buy)
      (position_side (Short)) (status New)
      (order_type (Other TRAILING_STOP_MARKET))
      (orig_type ((Other TRAILING_STOP_MARKET))) (time_in_force Gtc) (price 0)
      (orig_qty 0.4) (executed_qty 0) (cum_qty ()) (cum_quote (0))
      (avg_price (0)) (stop_price (9300)) (activate_price (9020))
      (price_rate (0.3)) (reduce_only false) (close_position false)
      (price_protect false) (working_type (Contract_price)) (price_match (NONE))
      (self_trade_prevention_mode (EXPIRE_MAKER)) (good_till_date (0))
      (time (1579276756075)) (update_time 1579276756075)))
    [{"orderId":1917641,"symbol":"BTCUSDT","clientOrderId":"abc","side":"BUY","positionSide":"SHORT","status":"NEW","type":"TRAILING_STOP_MARKET","origType":"TRAILING_STOP_MARKET","timeInForce":"GTC","price":"0","origQty":"0.4","executedQty":"0","cumQuote":"0","avgPrice":"0","stopPrice":"9300","activatePrice":"9020","priceRate":"0.3","reduceOnly":false,"closePosition":false,"priceProtect":false,"workingType":"CONTRACT_PRICE","priceMatch":"NONE","selfTradePreventionMode":"EXPIRE_MAKER","goodTillDate":0,"time":1579276756075,"updateTime":1579276756075}]
    ((symbol BTCUSDT) (side Buy) (px 0) (size 0.4) (orig_size (0.4))
     (order_id 1917641) (client_order_id (abc)) (timestamp 1579276756075000000))
    |}]
;;

let%expect_test "user trades" =
  Helpers.round_trip
    (module User_trade)
    {|{"buyer": false, "commission": "0.07819010", "commissionAsset": "USDT", "id": 698759,
       "maker": false, "orderId": 25851813, "price": "7819.01", "qty": "0.002",
       "quoteQty": "15.63802", "baseQty": "0", "marginAsset": "USDT",
       "realizedPnl": "-0.91539999", "side": "SELL", "positionSide": "SHORT",
       "symbol": "BTCUSDT", "pair": "BTCUSDT", "time": 1569514978020}|};
  [%expect
    {|
    ((id 698759) (order_id 25851813) (symbol BTCUSDT) (side Sell)
     (position_side (Short)) (price 7819.01) (qty 0.002) (quote_qty 15.63802)
     (commission 0.0781901) (commission_asset USDT) (realized_pnl -0.91539999)
     (margin_asset (USDT)) (maker false) (buyer false) (time 1569514978020))
    {"id":698759,"orderId":25851813,"symbol":"BTCUSDT","side":"SELL","positionSide":"SHORT","price":"7819.01","qty":"0.002","quoteQty":"15.63802","commission":"0.0781901","commissionAsset":"USDT","realizedPnl":"-0.91539999","marginAsset":"USDT","maker":false,"buyer":false,"time":1569514978020}
    |}]
;;

let%expect_test "account v3" =
  Helpers.round_trip
    (module Account)
    {|{"totalWalletBalance": "126.72469206", "totalUnrealizedProfit": "0.00000000",
       "totalMarginBalance": "126.72469206", "totalPositionInitialMargin": "0.00000000",
       "totalOpenOrderInitialMargin": "0.00000000", "totalCrossWalletBalance": "126.72469206",
       "totalCrossUnPnl": "0.00000000", "availableBalance": "126.72469206",
       "maxWithdrawAmount": "126.72469206",
       "assets": [{"asset": "USDT", "walletBalance": "23.72469206", "unrealizedProfit": "0.00000000",
                   "marginBalance": "23.72469206", "maintMargin": "0.00000000",
                   "initialMargin": "0.00000000", "positionInitialMargin": "0.00000000",
                   "openOrderInitialMargin": "0.00000000", "crossWalletBalance": "23.72469206",
                   "crossUnPnl": "0.00000000", "availableBalance": "23.72469206",
                   "maxWithdrawAmount": "23.72469206", "updateTime": 1625474304765}],
       "positions": [{"symbol": "BTCUSDT", "positionSide": "BOTH", "positionAmt": "1.000",
                      "unrealizedProfit": "0.00000000", "isolatedMargin": "0.00000000",
                      "notional": "0", "isolatedWallet": "0", "initialMargin": "0",
                      "maintMargin": "0", "updateTime": 0}]}|};
  [%expect
    {|
    ((total_wallet_balance 126.72469206) (total_unrealized_profit 0)
     (total_margin_balance 126.72469206) (total_initial_margin ())
     (total_maint_margin ()) (total_position_initial_margin (0))
     (total_open_order_initial_margin (0))
     (total_cross_wallet_balance (126.72469206)) (total_cross_un_pnl (0))
     (available_balance 126.72469206) (max_withdraw_amount (126.72469206))
     (can_trade ()) (fee_tier ()) (multi_assets_margin ()) (update_time ())
     (assets
      (((asset USDT) (wallet_balance 23.72469206) (unrealized_profit 0)
        (margin_balance 23.72469206) (maint_margin (0)) (initial_margin (0))
        (position_initial_margin (0)) (open_order_initial_margin (0))
        (cross_wallet_balance (23.72469206)) (cross_un_pnl (0))
        (available_balance 23.72469206) (max_withdraw_amount (23.72469206))
        (margin_available ()) (update_time 1625474304765))))
     (positions
      (((symbol BTCUSDT) (position_side Both) (position_amt 1) (entry_price ())
        (unrealized_profit 0) (leverage ()) (liquidation_price ()) (isolated ())
        (initial_margin (0)) (maint_margin (0)) (position_initial_margin ())
        (open_order_initial_margin ()) (isolated_margin (0))
        (isolated_wallet (0)) (notional (0)) (max_notional ()) (update_time 0)))))
    {"totalWalletBalance":"126.72469206","totalUnrealizedProfit":"0","totalMarginBalance":"126.72469206","totalPositionInitialMargin":"0","totalOpenOrderInitialMargin":"0","totalCrossWalletBalance":"126.72469206","totalCrossUnPnl":"0","availableBalance":"126.72469206","maxWithdrawAmount":"126.72469206","assets":[{"asset":"USDT","walletBalance":"23.72469206","unrealizedProfit":"0","marginBalance":"23.72469206","maintMargin":"0","initialMargin":"0","positionInitialMargin":"0","openOrderInitialMargin":"0","crossWalletBalance":"23.72469206","crossUnPnl":"0","availableBalance":"23.72469206","maxWithdrawAmount":"23.72469206","updateTime":1625474304765}],"positions":[{"symbol":"BTCUSDT","positionSide":"BOTH","positionAmt":"1","unrealizedProfit":"0","initialMargin":"0","maintMargin":"0","isolatedMargin":"0","isolatedWallet":"0","notional":"0","updateTime":0}]}
    |}]
;;

(* UNVERIFIED: the reference lists the v2 fields but has no full v2 example; this one is
   assembled from the field list and the schema's positions example. *)
let%expect_test "account v2" =
  Helpers.round_trip
    (module Account)
    {|{"feeTier": 0, "canTrade": true, "canDeposit": true, "canWithdraw": true,
       "updateTime": 0, "multiAssetsMargin": false, "tradeGroupId": -1,
       "totalInitialMargin": "0.00000000", "totalMaintMargin": "0.00000000",
       "totalWalletBalance": "103.12345678", "totalUnrealizedProfit": "0.00000000",
       "totalMarginBalance": "103.12345678", "totalPositionInitialMargin": "0.00000000",
       "totalOpenOrderInitialMargin": "0.00000000", "totalCrossWalletBalance": "103.12345678",
       "totalCrossUnPnl": "0.00000000", "availableBalance": "103.12345678",
       "maxWithdrawAmount": "103.12345678",
       "assets": [{"asset": "USDT", "walletBalance": "23.72469206", "unrealizedProfit": "0.00000000",
                   "marginBalance": "23.72469206", "maintMargin": "0.00000000",
                   "initialMargin": "0.00000000", "positionInitialMargin": "0.00000000",
                   "openOrderInitialMargin": "0.00000000", "crossWalletBalance": "23.72469206",
                   "crossUnPnl": "0.00000000", "availableBalance": "23.72469206",
                   "maxWithdrawAmount": "23.72469206", "marginAvailable": true,
                   "updateTime": 1625474304765}],
       "positions": [{"symbol":"BTCUSDT","initialMargin":"0","maintMargin":"0",
                      "unrealizedProfit":"0.00000000","positionInitialMargin":"0",
                      "openOrderInitialMargin":"0","leverage":"100","isolated":true,
                      "entryPrice":"0.00000","maxNotional":"250000","bidNotional":"0",
                      "askNotional":"0","positionSide":"BOTH","positionAmt":"0","updateTime":0}]}|};
  [%expect
    {|
    ((total_wallet_balance 103.12345678) (total_unrealized_profit 0)
     (total_margin_balance 103.12345678) (total_initial_margin (0))
     (total_maint_margin (0)) (total_position_initial_margin (0))
     (total_open_order_initial_margin (0))
     (total_cross_wallet_balance (103.12345678)) (total_cross_un_pnl (0))
     (available_balance 103.12345678) (max_withdraw_amount (103.12345678))
     (can_trade (true)) (fee_tier (0)) (multi_assets_margin (false))
     (update_time (0))
     (assets
      (((asset USDT) (wallet_balance 23.72469206) (unrealized_profit 0)
        (margin_balance 23.72469206) (maint_margin (0)) (initial_margin (0))
        (position_initial_margin (0)) (open_order_initial_margin (0))
        (cross_wallet_balance (23.72469206)) (cross_un_pnl (0))
        (available_balance 23.72469206) (max_withdraw_amount (23.72469206))
        (margin_available (true)) (update_time 1625474304765))))
     (positions
      (((symbol BTCUSDT) (position_side Both) (position_amt 0) (entry_price (0))
        (unrealized_profit 0) (leverage (100)) (liquidation_price ())
        (isolated (true)) (initial_margin (0)) (maint_margin (0))
        (position_initial_margin (0)) (open_order_initial_margin (0))
        (isolated_margin ()) (isolated_wallet ()) (notional ())
        (max_notional (250000)) (update_time 0)))))
    {"totalWalletBalance":"103.12345678","totalUnrealizedProfit":"0","totalMarginBalance":"103.12345678","totalInitialMargin":"0","totalMaintMargin":"0","totalPositionInitialMargin":"0","totalOpenOrderInitialMargin":"0","totalCrossWalletBalance":"103.12345678","totalCrossUnPnl":"0","availableBalance":"103.12345678","maxWithdrawAmount":"103.12345678","canTrade":true,"feeTier":0,"multiAssetsMargin":false,"updateTime":0,"assets":[{"asset":"USDT","walletBalance":"23.72469206","unrealizedProfit":"0","marginBalance":"23.72469206","maintMargin":"0","initialMargin":"0","positionInitialMargin":"0","openOrderInitialMargin":"0","crossWalletBalance":"23.72469206","crossUnPnl":"0","availableBalance":"23.72469206","maxWithdrawAmount":"23.72469206","marginAvailable":true,"updateTime":1625474304765}],"positions":[{"symbol":"BTCUSDT","positionSide":"BOTH","positionAmt":"0","entryPrice":"0","unrealizedProfit":"0","leverage":"100","isolated":true,"initialMargin":"0","maintMargin":"0","positionInitialMargin":"0","openOrderInitialMargin":"0","maxNotional":"250000","updateTime":0}]}
    |}]
;;

let%expect_test "position risk v2 and v3" =
  Helpers.round_trip
    (module Position_risk)
    {|{"entryPrice": "0.00000", "breakEvenPrice": "0.0", "marginType": "isolated",
       "isAutoAddMargin": "false", "isolatedMargin": "0.00000000", "leverage": "10",
       "liquidationPrice": "0", "markPrice": "6679.50671178", "maxNotionalValue": "20000000",
       "positionAmt": "0.000", "notional": "0", "isolatedWallet": "0", "symbol": "BTCUSDT",
       "unRealizedProfit": "0.00000000", "positionSide": "BOTH", "updateTime": 1625474304765}|};
  Helpers.round_trip
    (module Position_risk)
    {|{"symbol": "ADAUSDT", "positionSide": "BOTH", "positionAmt": "30", "entryPrice": "0.385",
       "breakEvenPrice": "0.385077", "markPrice": "0.41047590", "unRealizedProfit": "0.76427700",
       "liquidationPrice": "0", "isolatedMargin": "0", "notional": "12.31427700",
       "marginAsset": "USDT", "isolatedWallet": "0", "initialMargin": "0.61571385",
       "maintMargin": "0.08004280", "positionInitialMargin": "0.61571385",
       "openOrderInitialMargin": "0", "adl": 2, "bidNotional": "0", "askNotional": "0",
       "updateTime": 1720736417660}|};
  [%expect
    {|
    ((symbol BTCUSDT) (position_side Both) (position_amt 0) (entry_price 0)
     (break_even_price (0)) (mark_price 6679.50671178) (unrealized_profit 0)
     (liquidation_price 0) (isolated_margin (0)) (notional (0))
     (isolated_wallet (0)) (margin_asset ()) (leverage (10))
     (margin_type (isolated)) (is_auto_add_margin (false))
     (max_notional_value (20000000)) (initial_margin ()) (maint_margin ())
     (position_initial_margin ()) (open_order_initial_margin ()) (adl ())
     (update_time 1625474304765))
    {"symbol":"BTCUSDT","positionSide":"BOTH","positionAmt":"0","entryPrice":"0","breakEvenPrice":"0","markPrice":"6679.50671178","unRealizedProfit":"0","liquidationPrice":"0","isolatedMargin":"0","notional":"0","isolatedWallet":"0","leverage":"10","marginType":"isolated","isAutoAddMargin":"false","maxNotionalValue":"20000000","updateTime":1625474304765}
    ((symbol ADAUSDT) (position_side Both) (position_amt 30) (entry_price 0.385)
     (break_even_price (0.385077)) (mark_price 0.4104759)
     (unrealized_profit 0.764277) (liquidation_price 0) (isolated_margin (0))
     (notional (12.314277)) (isolated_wallet (0)) (margin_asset (USDT))
     (leverage ()) (margin_type ()) (is_auto_add_margin ())
     (max_notional_value ()) (initial_margin (0.61571385))
     (maint_margin (0.0800428)) (position_initial_margin (0.61571385))
     (open_order_initial_margin (0)) (adl (2)) (update_time 1720736417660))
    {"symbol":"ADAUSDT","positionSide":"BOTH","positionAmt":"30","entryPrice":"0.385","breakEvenPrice":"0.385077","markPrice":"0.4104759","unRealizedProfit":"0.764277","liquidationPrice":"0","isolatedMargin":"0","notional":"12.314277","isolatedWallet":"0","marginAsset":"USDT","initialMargin":"0.61571385","maintMargin":"0.0800428","positionInitialMargin":"0.61571385","openOrderInitialMargin":"0","adl":2,"updateTime":1720736417660}
    |}]
;;

let%expect_test "listen key" =
  Helpers.round_trip
    (module Listen_key)
    {|{"listenKey": "pqia91ma19a5s61cv6a81va65sdf19v8a65a1a5s61cv6a81va65sdf19v8a65a1"}|};
  [%expect
    {|
    ((listen_key
      pqia91ma19a5s61cv6a81va65sdf19v8a65a1a5s61cv6a81va65sdf19v8a65a1))
    {"listenKey":"pqia91ma19a5s61cv6a81va65sdf19v8a65a1a5s61cv6a81va65sdf19v8a65a1"}
    |}]
;;

let%expect_test "errors" =
  List.iter
    [ {|{"code": -1121, "msg": "Invalid symbol."}|}
    ; {|{"code": -4164, "msg": "Order's notional must be no smaller than 20 (unless you choose reduce only)."}|}
    ; {|{"code": -5022, "msg": "Due to the order could not be executed as maker, the Post Only order will be rejected."}|}
    ; {|{"code": -9999, "msg": "?"}|}
    ]
    ~f:(fun json ->
      Helpers.round_trip (module Api_error) json;
      let error = Api_error.t_of_yojson (Yojson.Safe.from_string json) in
      print_s
        [%sexp (Api_error.to_reject_reason error : Exchange_core.Reject_reason.t option)]);
  print_s
    [%sexp
      (Api_error.of_yojson_opt (Yojson.Safe.from_string new_order_response)
       : Api_error.t option)];
  [%expect
    {|
    ((code Bad_symbol) (msg "Invalid symbol."))
    {"code":-1121,"msg":"Invalid symbol."}
    (Unknown_symbol)
    ((code Min_notional)
     (msg
      "Order's notional must be no smaller than 20 (unless you choose reduce only)."))
    {"code":-4164,"msg":"Order's notional must be no smaller than 20 (unless you choose reduce only)."}
    ((Below_min_value (min 20)))
    ((code Gtx_order_reject)
     (msg
      "Due to the order could not be executed as maker, the Post Only order will be rejected."))
    {"code":-5022,"msg":"Due to the order could not be executed as maker, the Post Only order will be rejected."}
    ((Post_only_would_cross (best_bid ()) (best_ask ())))
    ((code (Other -9999)) (msg ?))
    {"code":-9999,"msg":"?"}
    ()
    ()
    |}]
;;
