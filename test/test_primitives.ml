open! Core
open Binance_protocol

let json_string to_yojson v = Yojson.Safe.to_string (to_yojson v)

let%expect_test "side, time in force, position side, working type" =
  List.iter Side.all ~f:(fun v -> print_endline (json_string Side.yojson_of_t v));
  List.iter Time_in_force.all ~f:(fun v ->
    print_s
      [%sexp
        (json_string Time_in_force.yojson_of_t v : string)
        , (Time_in_force.to_tif v : Exchange_core.Tif.t option)]);
  List.iter Position_side.all ~f:(fun v ->
    print_endline (json_string Position_side.yojson_of_t v));
  List.iter Working_type.all ~f:(fun v ->
    print_endline (json_string Working_type.yojson_of_t v));
  [%expect
    {|
    "BUY"
    "SELL"
    ("\"GTC\"" (Gtc))
    ("\"IOC\"" (Ioc))
    ("\"FOK\"" ())
    ("\"GTX\"" (Alo))
    ("\"GTD\"" ())
    ("\"RPI\"" ())
    "BOTH"
    "LONG"
    "SHORT"
    "MARK_PRICE"
    "CONTRACT_PRICE"
    |}]
;;

let%expect_test "open enums keep unknown values" =
  List.iter [ "LIMIT"; "MARKET"; "STOP_MARKET" ] ~f:(fun s ->
    print_s [%sexp (Order_type.of_wire s : Order_type.t)]);
  List.iter [ "NEW"; "EXPIRED_IN_MATCH"; "REJECTED" ] ~f:(fun s ->
    let status = Order_status.of_wire s in
    print_s [%sexp (status : Order_status.t), (Order_status.is_final status : bool)]);
  List.iter [ "TRADE"; "CALCULATED"; "NEW_EXEC" ] ~f:(fun s ->
    print_s [%sexp (Execution_type.of_wire s : Execution_type.t)]);
  [%expect
    {|
    Limit
    Market
    (Other STOP_MARKET)
    (New false)
    (Expired_in_match true)
    ((Other REJECTED) false)
    Trade
    Calculated
    (Other NEW_EXEC)
    |}]
;;

let%expect_test "symbol is uppercase, stream prefix lowercase" =
  let s = Symbol.t_of_yojson (`String "btcUSDT") in
  print_s
    [%sexp
      (s : Symbol.t)
      , (Symbol.to_stream_prefix s : string)
      , (Symbol.t_of_sexp (Sexp.Atom "ethusdt") : Symbol.t)];
  [%expect {| (BTCUSDT btcusdt ETHUSDT) |}]
;;

let%expect_test "client order ids" =
  List.iter
    [ "my-order_1"; "a.b:c/d"; ""; "has space"; String.make 37 'x' ]
    ~f:(fun s ->
      print_s [%sexp (Client_order_id.validate s : Client_order_id.t Or_error.t)]);
  List.iter [ "autoclose-123"; "adl_autoclose"; "mine" ] ~f:(fun s ->
    print_s
      [%sexp (Client_order_id.is_exchange_generated (Client_order_id.of_string s) : bool)]);
  [%expect
    {|
    (Ok my-order_1)
    (Ok a.b:c/d)
    (Error ("Client_order_id: invalid" ""))
    (Error ("Client_order_id: invalid" "has space"))
    (Error ("Client_order_id: invalid" xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx))
    true
    true
    false
    |}]
;;

let%expect_test "decimal strings and string-encoded ints and bools" =
  List.iter [ "0.00000"; "11793.63104562"; "-0.91539999"; "0.2732781800" ] ~f:(fun s ->
    print_endline (json_string Price.yojson_of_t (Price.of_string s)));
  print_s
    [%sexp
      (Json.Int_string.t_of_yojson (`String "125") : int)
      , (Json.Bool_string.t_of_yojson (`String "false") : bool)];
  [%expect
    {|
    "0"
    "11793.63104562"
    "-0.91539999"
    "0.27327818"
    (125 false)
    |}]
;;

let%expect_test "timestamps" =
  let t = Timestamp_ms.of_int 1591702613943 in
  print_s [%sexp (Timestamp_ms.to_time_ns t : Time_ns.Alternate_sexp.t)];
  print_s [%sexp (Timestamp_ms.of_time_ns (Timestamp_ms.to_time_ns t) : Timestamp_ms.t)];
  [%expect {|
    "2020-06-09 11:36:53.943Z"
    1591702613943
    |}]
;;
