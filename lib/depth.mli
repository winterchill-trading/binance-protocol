(** Order book snapshot from [GET /fapi/v1/depth]:
    [{"lastUpdateId": 1027024, "E": 1589436922972, "T": 1589436922959, "bids": [["4.00000000", "431.00000000"]], "asks": [...]}].
    Best price first on each side. *)

open! Core

type t =
  { last_update_id : int
  ; event_time : Timestamp_ms.t (** [E]: message output time *)
  ; transaction_time : Timestamp_ms.t (** [T]: matching engine time *)
  ; bids : Book_level.t list
  ; asks : Book_level.t list
  }
[@@deriving sexp, compare, equal, yojson]
