open! Core
open Binance_protocol

(* The worked example from the signing section of the API docs. *)
let secret = "2b5eb11e18796d12d88f13dc27dbbd02c2cc51ff7059765ed9821957d82bb4d9"

let%expect_test "documented test vector" =
  let query_string =
    "symbol=BTCUSDT&side=BUY&type=LIMIT&quantity=1&price=9000&timeInForce=GTC&recvWindow=5000&timestamp=1591702613943"
  in
  print_endline (Signature.sign ~secret ~query_string);
  [%expect {| 3c661234138461fcc7a7d8746c6558c9842d4e10870d2ecbedf7777cad694af9 |}]
;;

let%expect_test "signed query from a new order" =
  let request =
    New_order.Request.limit
      (Symbol.of_string "BTCUSDT")
      Buy
      ~price:(Price.of_int 9000)
      ~quantity:(Size.of_int 1)
  in
  print_endline
    (Signature.signed_query
       ~secret
       ~recv_window:5000
       ~timestamp:(Timestamp_ms.of_int 1591702613943)
       (New_order.Request.to_params request));
  [%expect
    {| symbol=BTCUSDT&side=BUY&type=LIMIT&timeInForce=GTC&quantity=1&price=9000&recvWindow=5000&timestamp=1591702613943&signature=ec11dcc17e67e47f0d3c3f513dfe9062307e37619c5c82ebaa8fe0bdf3d59519 |}]
;;

let%expect_test "percent encoding" =
  print_endline
    (Query.encode
       [ "newClientOrderId", "a b/c:d"
       ; "batchOrders", {|[{"symbol":"BTCUSDT"}]|}
       ; "x", "-_.~"
       ]);
  [%expect
    {| newClientOrderId=a%20b%2Fc%3Ad&batchOrders=%5B%7B%22symbol%22%3A%22BTCUSDT%22%7D%5D&x=-_.~ |}]
;;
