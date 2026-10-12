open! Core
open Ppx_yojson_conv_lib.Yojson_conv.Primitives

module T = struct
  type t =
    { event_time : Timestamp_ms.t [@key "E"]
    ; listen_key : string [@key "listenKey"]
    }
  [@@deriving sexp, compare, equal, yojson] [@@yojson.allow_extra_fields]
end

include T

let event_type = "listenKeyExpired"
let yojson_of_t t = Json.with_tag (T.yojson_of_t t) ~key:"e" ~value:event_type
