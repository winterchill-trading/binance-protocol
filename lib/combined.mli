(** Combined-stream wrapper ([/stream?streams=a/b]):
    [{"stream": "btcusdt@aggTrade", "data": {...}}]. Instantiate with the payload type,
    e.g. [Market_event.t Combined.t]. *)

open! Core

type 'a t =
  { stream : Stream_name.t
  ; data : 'a
  }
[@@deriving sexp, compare, equal, yojson]
