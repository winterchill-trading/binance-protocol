(** Diff-depth event ([<symbol>@depth], [@depth@100ms]) and, per the shape assumed here,
    partial-depth event ([<symbol>@depth5/10/20]):
    [{"e": "depthUpdate", "E": 1571889248277, "T": 1571889248276, "s": "BTCUSDT", "U": 390497796, "u": 390497878, "pu": 390497794, "b": [["7403.89", "0.002"]], "a": [["7405.96", "3.340"]]}].

    For diff depth, quantities are absolute and zero removes the level. Keep a local book
    by applying events whose [pu] equals the previous event's [u]; resync from {!Depth}
    otherwise. For partial depth, [b]/[a] hold the full top N levels. *)

open! Core

type t =
  { event_time : Timestamp_ms.t (** [E] *)
  ; transaction_time : Timestamp_ms.t (** [T] *)
  ; symbol : Symbol.t (** [s] *)
  ; first_update_id : int (** [U] *)
  ; final_update_id : int (** [u] *)
  ; prev_final_update_id : int (** [pu] *)
  ; bids : Book_level.t list (** [b] *)
  ; asks : Book_level.t list (** [a] *)
  }
[@@deriving sexp, compare, equal, yojson]

(** ["depthUpdate"], written as ["e"] by the encoder. *)
val event_type : string
