open! Core
open Binance_protocol

let round_trip = Helpers.round_trip (module User_event)

let%expect_test "order trade update" =
  round_trip
    {|{"e":"ORDER_TRADE_UPDATE","E":1568879465651,"T":1568879465650,
       "o":{"s":"BTCUSDT","c":"TEST","S":"SELL","o":"TRAILING_STOP_MARKET","f":"GTC","q":"0.001",
            "p":"0","ap":"0","sp":"7103.04","x":"EXPIRED","X":"EXPIRED_IN_MATCH","i":8886774,
            "l":"0","z":"0","L":"0","N":"USDT","n":"0","T":1568879465650,"t":0,"b":"0",
            "a":"9.91","m":false,"R":false,"wt":"CONTRACT_PRICE","ot":"TRAILING_STOP_MARKET",
            "ps":"LONG","cp":false,"AP":"7476.89","cr":"5.0","pP":false,"si":0,"ss":0,
            "rp":"0","V":"EXPIRE_MAKER","pm":"QUEUE","gtd":1768879465650}}|};
  [%expect
    {|
    (Order_trade_update
     ((event_time 1568879465651) (transaction_time 1568879465650)
      (order
       ((symbol BTCUSDT) (client_order_id TEST) (side Sell)
        (order_type (Other TRAILING_STOP_MARKET)) (time_in_force Gtc)
        (orig_qty 0.001) (price 0) (avg_price 0) (stop_price (7103.04))
        (execution_type Expired) (status Expired_in_match) (order_id 8886774)
        (last_filled_qty 0) (cum_filled_qty 0) (last_filled_price 0)
        (commission_asset (USDT)) (commission (0)) (trade_time 1568879465650)
        (trade_id 0) (bids_notional (0)) (asks_notional (9.91)) (is_maker false)
        (reduce_only false) (working_type (Contract_price))
        (orig_type ((Other TRAILING_STOP_MARKET))) (position_side (Long))
        (close_position false) (activation_price (7476.89)) (callback_rate (5))
        (price_protect false) (si (0)) (ss (0)) (realized_profit 0)
        (self_trade_prevention_mode (EXPIRE_MAKER)) (price_match (QUEUE))
        (good_till_date (1768879465650)) (expiry_reason ())))))
    {"e":"ORDER_TRADE_UPDATE","E":1568879465651,"T":1568879465650,"o":{"s":"BTCUSDT","c":"TEST","S":"SELL","o":"TRAILING_STOP_MARKET","f":"GTC","q":"0.001","p":"0","ap":"0","sp":"7103.04","x":"EXPIRED","X":"EXPIRED_IN_MATCH","i":8886774,"l":"0","z":"0","L":"0","N":"USDT","n":"0","T":1568879465650,"t":0,"b":"0","a":"9.91","m":false,"R":false,"wt":"CONTRACT_PRICE","ot":"TRAILING_STOP_MARKET","ps":"LONG","cp":false,"AP":"7476.89","cr":"5","pP":false,"si":0,"ss":0,"rp":"0","V":"EXPIRE_MAKER","pm":"QUEUE","gtd":1768879465650}}
    |}]
;;

let%expect_test "order trade update: a maker fill without commission fields" =
  round_trip
    {|{"e":"ORDER_TRADE_UPDATE","E":1700000000001,"T":1700000000000,
       "o":{"s":"ETHUSDT","c":"mm-42","S":"BUY","o":"LIMIT","f":"GTX","q":"0.10","p":"2000.00",
            "ap":"2000.00","sp":"0","x":"TRADE","X":"PARTIALLY_FILLED","i":123,"l":"0.04",
            "z":"0.04","L":"2000.00","T":1700000000000,"t":987,"b":"120","a":"0","m":true,
            "R":false,"wt":"CONTRACT_PRICE","ot":"LIMIT","ps":"BOTH","cp":false,"rp":"0",
            "er":"0"}}|};
  [%expect
    {|
    (Order_trade_update
     ((event_time 1700000000001) (transaction_time 1700000000000)
      (order
       ((symbol ETHUSDT) (client_order_id mm-42) (side Buy) (order_type Limit)
        (time_in_force Gtx) (orig_qty 0.1) (price 2000) (avg_price 2000)
        (stop_price (0)) (execution_type Trade) (status Partially_filled)
        (order_id 123) (last_filled_qty 0.04) (cum_filled_qty 0.04)
        (last_filled_price 2000) (commission_asset ()) (commission ())
        (trade_time 1700000000000) (trade_id 987) (bids_notional (120))
        (asks_notional (0)) (is_maker true) (reduce_only false)
        (working_type (Contract_price)) (orig_type (Limit))
        (position_side (Both)) (close_position false) (activation_price ())
        (callback_rate ()) (price_protect false) (si ()) (ss ())
        (realized_profit 0) (self_trade_prevention_mode ()) (price_match ())
        (good_till_date ()) (expiry_reason (0))))))
    {"e":"ORDER_TRADE_UPDATE","E":1700000000001,"T":1700000000000,"o":{"s":"ETHUSDT","c":"mm-42","S":"BUY","o":"LIMIT","f":"GTX","q":"0.1","p":"2000","ap":"2000","sp":"0","x":"TRADE","X":"PARTIALLY_FILLED","i":123,"l":"0.04","z":"0.04","L":"2000","T":1700000000000,"t":987,"b":"120","a":"0","m":true,"R":false,"wt":"CONTRACT_PRICE","ot":"LIMIT","ps":"BOTH","cp":false,"pP":false,"rp":"0","er":"0"}}
    |}]
;;

let%expect_test "account update" =
  round_trip
    {|{"e":"ACCOUNT_UPDATE","T":1679974782150,"E":1679974782155,
       "a":{"B":[{"a":"USDT","wb":"685.31478079","cw":"677.17212454","bc":"0.00258637"}],
            "P":[],"m":"ADMIN_DEPOSIT"}}|};
  [%expect
    {|
    (Account_update
     ((event_time 1679974782155) (transaction_time 1679974782150)
      (reason Admin_deposit)
      (balances
       (((asset USDT) (wallet_balance 685.31478079)
         (cross_wallet_balance 677.17212454) (balance_change 0.00258637))))
      (positions ())))
    {"e":"ACCOUNT_UPDATE","E":1679974782155,"T":1679974782150,"a":{"B":[{"a":"USDT","wb":"685.31478079","cw":"677.17212454","bc":"0.00258637"}],"P":[],"m":"ADMIN_DEPOSIT"}}
    |}]
;;

(* UNVERIFIED: the position fields of ACCOUNT_UPDATE are not in the fetched reference. *)
let%expect_test "account update with a position" =
  round_trip
    {|{"e":"ACCOUNT_UPDATE","E":1564745798939,"T":1564745798938,
       "a":{"m":"ORDER",
            "B":[{"a":"USDT","wb":"122624.12345678","cw":"100.12345678","bc":"50.12345678"}],
            "P":[{"s":"BTCUSDT","pa":"-0.020","ep":"9000.00000","bep":"9000.1","cr":"200",
                  "up":"0.2732781800","mt":"isolated","iw":"0.06391979","ps":"BOTH"}]}}|};
  [%expect
    {|
    (Account_update
     ((event_time 1564745798939) (transaction_time 1564745798938) (reason Order)
      (balances
       (((asset USDT) (wallet_balance 122624.12345678)
         (cross_wallet_balance 100.12345678) (balance_change 50.12345678))))
      (positions
       (((symbol BTCUSDT) (position_amt -0.02) (entry_price 9000)
         (breakeven_price (9000.1)) (accumulated_realized (200))
         (unrealized_pnl 0.27327818) (margin_type (isolated))
         (isolated_wallet (0.06391979)) (position_side Both))))))
    {"e":"ACCOUNT_UPDATE","E":1564745798939,"T":1564745798938,"a":{"B":[{"a":"USDT","wb":"122624.12345678","cw":"100.12345678","bc":"50.12345678"}],"P":[{"s":"BTCUSDT","pa":"-0.02","ep":"9000","bep":"9000.1","cr":"200","up":"0.27327818","mt":"isolated","iw":"0.06391979","ps":"BOTH"}],"m":"ORDER"}}
    |}]
;;

let%expect_test "listen key expired" =
  round_trip
    {|{"e":"listenKeyExpired","E":1736996475556,"listenKey":"WsCMN0a4KHUPTQuX6IUnqEZfB1inxmv1qR4kbf1LuEjur5VdbzqvyxqG9TSjVVxv"}|};
  [%expect
    {|
    (Listen_key_expired
     ((event_time 1736996475556)
      (listen_key
       WsCMN0a4KHUPTQuX6IUnqEZfB1inxmv1qR4kbf1LuEjur5VdbzqvyxqG9TSjVVxv)))
    {"e":"listenKeyExpired","E":1736996475556,"listenKey":"WsCMN0a4KHUPTQuX6IUnqEZfB1inxmv1qR4kbf1LuEjur5VdbzqvyxqG9TSjVVxv"}
    |}]
;;

let%expect_test "unknown events" =
  round_trip {|{"e":"MARGIN_CALL","E":1587727187525,"cw":"3.16812045","p":[]}|};
  [%expect
    {|
    (Unknown (event_type (MARGIN_CALL))
     (json
      "{\"e\":\"MARGIN_CALL\",\"E\":1587727187525,\"cw\":\"3.16812045\",\"p\":[]}"))
    {"e":"MARGIN_CALL","E":1587727187525,"cw":"3.16812045","p":[]}
    |}]
;;
