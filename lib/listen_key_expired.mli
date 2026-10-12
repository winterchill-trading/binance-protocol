(** User-data event [listenKeyExpired]:
    [{"e": "listenKeyExpired", "E": 1736996475556, "listenKey": "WsCMN0a4..."}]. No more
    user events arrive on the connection; create a new key and reconnect. *)

open! Core

type t =
  { event_time : Timestamp_ms.t (** [E] *)
  ; listen_key : string
  }
[@@deriving sexp, compare, equal, yojson]

val event_type : string
