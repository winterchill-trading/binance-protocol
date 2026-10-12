(** [POST /fapi/v1/batchOrders]: up to 5 new orders in one request. *)

open! Core

module Request : sig
  type t = private New_order.Request.t list [@@deriving sexp, compare, equal]

  val max_orders : int

  (** Errors on an empty list or more than {!max_orders} orders. *)
  val create : New_order.Request.t list -> t Or_error.t

  val orders : t -> New_order.Request.t list

  (** [[("batchOrders", <JSON array>)]]; every value inside the array is a string. The
      caller form-encodes it (see {!Query.encode}). *)
  val to_params : t -> (string * string) list
end

module Response : sig
  module Item : sig
    (** Each element is either an order or [{"code": ..., "msg": ...}]. *)
    type t =
      | Ok of Order.t
      | Error of Api_error.t
    [@@deriving sexp, compare, equal, yojson]
  end

  (** One item per submitted order, in submission order. *)
  type t = Item.t list [@@deriving sexp, compare, equal, yojson]
end
