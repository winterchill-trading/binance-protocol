open! Core

(** Decodes [json], prints the value as a sexp and its re-encoding, and checks that
    decoding the re-encoding yields an equal value. *)
val round_trip : (module Binance_protocol.Codec.S with type t = 'a) -> string -> unit
