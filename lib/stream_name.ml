open! Core

module Speed = struct
  type t =
    | Ms_100
    | Ms_250
    | Ms_500
  [@@deriving sexp, compare, equal, hash, enumerate]

  let to_string = function
    | Ms_100 -> "100ms"
    | Ms_250 -> "250ms"
    | Ms_500 -> "500ms"
  ;;

  let of_string s = List.find all ~f:(fun t -> String.equal (to_string t) s)
end

type t =
  | Diff_depth of
      { symbol : Symbol.t
      ; speed : Speed.t option
      }
  | Partial_depth of
      { symbol : Symbol.t
      ; levels : int
      ; speed : Speed.t option
      }
  | Agg_trade of Symbol.t
  | Book_ticker of Symbol.t
  | Mark_price of
      { symbol : Symbol.t
      ; every_second : bool
      }
  | Other of string
[@@deriving sexp, compare, equal, hash]

let valid_levels levels = List.mem [ 5; 10; 20 ] levels ~equal:Int.equal

let to_string t =
  let with_speed base speed =
    match speed with
    | None -> base
    | Some speed -> base ^ "@" ^ Speed.to_string speed
  in
  match t with
  | Diff_depth { symbol; speed } ->
    with_speed (Symbol.to_stream_prefix symbol ^ "@depth") speed
  | Partial_depth { symbol; levels; speed } ->
    with_speed (sprintf "%s@depth%d" (Symbol.to_stream_prefix symbol) levels) speed
  | Agg_trade symbol -> Symbol.to_stream_prefix symbol ^ "@aggTrade"
  | Book_ticker symbol -> Symbol.to_stream_prefix symbol ^ "@bookTicker"
  | Mark_price { symbol; every_second } ->
    Symbol.to_stream_prefix symbol ^ "@markPrice" ^ if every_second then "@1s" else ""
  | Other s -> s
;;

let of_string s =
  let parsed =
    match String.split s ~on:'@' with
    | [ ""; _ ] | [ ""; _; _ ] -> None
    | [ symbol; kind ] -> Some (Symbol.of_string symbol, kind, None)
    | [ symbol; kind; suffix ] -> Some (Symbol.of_string symbol, kind, Some suffix)
    | _ -> None
  in
  let speed suffix ~f =
    match suffix with
    | None -> Some (f None)
    | Some suffix -> Option.map (Speed.of_string suffix) ~f:(fun s -> f (Some s))
  in
  let result =
    match parsed with
    | None -> None
    | Some (symbol, "depth", suffix) ->
      speed suffix ~f:(fun speed -> Diff_depth { symbol; speed })
    | Some (symbol, "aggTrade", None) -> Some (Agg_trade symbol)
    | Some (symbol, "bookTicker", None) -> Some (Book_ticker symbol)
    | Some (symbol, "markPrice", None) ->
      Some (Mark_price { symbol; every_second = false })
    | Some (symbol, "markPrice", Some "1s") ->
      Some (Mark_price { symbol; every_second = true })
    | Some (symbol, kind, suffix) ->
      (match String.chop_prefix kind ~prefix:"depth" with
       | Some n ->
         (match Int.of_string_opt n with
          | Some levels when valid_levels levels ->
            speed suffix ~f:(fun speed -> Partial_depth { symbol; levels; speed })
          | _ -> None)
       | None -> None)
  in
  (* Only accept a parse that prints back to the same name, e.g. not "BTCUSDT@depth". *)
  match result with
  | Some t when String.equal (to_string t) s -> t
  | _ -> Other s
;;

let partial_depth ?speed symbol ~levels =
  if valid_levels levels
  then Ok (Partial_depth { symbol; levels; speed })
  else
    Or_error.error_s
      [%message "Stream_name: depth levels must be 5, 10 or 20" (levels : int)]
;;

let yojson_of_t t : Yojson.Safe.t = `String (to_string t)

let t_of_yojson (json : Yojson.Safe.t) =
  match json with
  | `String s -> of_string s
  | _ -> Json.error "Stream_name: string expected" json
;;
