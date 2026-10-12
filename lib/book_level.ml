open! Core

type t =
  { price : Price.t
  ; qty : Size.t
  }
[@@deriving sexp, compare, equal]

let yojson_of_t { price; qty } : Yojson.Safe.t =
  `List [ Price.yojson_of_t price; Size.yojson_of_t qty ]
;;

let t_of_yojson (json : Yojson.Safe.t) =
  match json with
  | `List [ price; qty ] ->
    { price = Price.t_of_yojson price; qty = Size.t_of_yojson qty }
  | _ -> Json.error "Book_level: [price, qty] expected" json
;;
