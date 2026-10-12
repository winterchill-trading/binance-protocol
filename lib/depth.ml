open! Core
open Ppx_yojson_conv_lib.Yojson_conv.Primitives

type t =
  { last_update_id : int [@key "lastUpdateId"]
  ; event_time : Timestamp_ms.t [@key "E"]
  ; transaction_time : Timestamp_ms.t [@key "T"]
  ; bids : Book_level.t list
  ; asks : Book_level.t list
  }
[@@deriving sexp, compare, equal, yojson] [@@yojson.allow_extra_fields]
