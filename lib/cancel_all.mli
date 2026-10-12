(** [DELETE /fapi/v1/allOpenOrders]: cancels every open order on one symbol. *)

open! Core

module Request : sig
  type t = { symbol : Symbol.t } [@@deriving sexp, compare, equal]

  val to_params : t -> (string * string) list
end

module Response : sig
  (** [{"code": 200, "msg": "The operation of cancel all open order is done."}]. The same
      shape as {!Api_error.t}, with code 200 on success. *)
  type t =
    { code : int
    ; msg : string
    }
  [@@deriving sexp, compare, equal, yojson]

  val is_success : t -> bool
end
