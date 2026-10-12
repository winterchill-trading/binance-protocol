open! Core
open Ppx_yojson_conv_lib.Yojson_conv.Primitives

(* UNVERIFIED: the USD-M payload example is from memory, not the fetched reference (the
   field list matches the changelog). Partial-depth streams are assumed to use the same
   shape; the reference's changelog instead lists lastUpdateId/E/T/bids/asks for them,
   which Market_event decodes as Depth_snapshot. *)
module T = struct
  type t =
    { event_time : Timestamp_ms.t [@key "E"]
    ; transaction_time : Timestamp_ms.t [@key "T"]
    ; symbol : Symbol.t [@key "s"]
    ; first_update_id : int [@key "U"]
    ; final_update_id : int [@key "u"]
    ; prev_final_update_id : int [@key "pu"]
    ; bids : Book_level.t list [@key "b"]
    ; asks : Book_level.t list [@key "a"]
    }
  [@@deriving sexp, compare, equal, yojson] [@@yojson.allow_extra_fields]
end

include T

let event_type = "depthUpdate"
let yojson_of_t t = Json.with_tag (T.yojson_of_t t) ~key:"e" ~value:event_type
