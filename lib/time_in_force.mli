(** Time in force ([timeInForce], [f]). [Gtx] is post-only; [Gtd] needs [goodTillDate];
    [Rpi] is retail-price-improvement (post-only, hidden from the public book). *)

open! Core

type t =
  | Gtc
  | Ioc
  | Fok
  | Gtx
  | Gtd
  | Rpi
[@@deriving sexp, compare, equal, hash, enumerate, yojson]

(** The JSON string used on the wire. *)
val to_wire : t -> string

val of_wire : string -> t option

(** [Gtc], [Ioc], and [Alo] as [Gtx]. *)
val of_tif : Exchange_core.Tif.t -> t

(** [None] for [Fok], [Gtd] and [Rpi], which have no venue-neutral counterpart. *)
val to_tif : t -> Exchange_core.Tif.t option
