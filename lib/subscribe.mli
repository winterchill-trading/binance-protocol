(** Live subscription management on an open market-stream connection. *)

open! Core

module Method : sig
  type t =
    | Subscribe
    | Unsubscribe
    | List_subscriptions
  [@@deriving sexp, compare, equal, hash, enumerate, yojson]
end

module Request : sig
  (** [{"method": "SUBSCRIBE", "params": ["btcusdt@aggTrade", "btcusdt@depth"], "id": 1}].
      [params] is omitted for [LIST_SUBSCRIPTIONS]. [id] is an unsigned integer echoed in
      the response. *)
  type t =
    { method_ : Method.t
    ; params : Stream_name.t list
    ; id : int
    }
  [@@deriving sexp, compare, equal, yojson]
end

module Response : sig
  type t =
    | Result of
        { result : Json.t (** [null], or the stream list for [LIST_SUBSCRIPTIONS] *)
        ; id : int
        }
    | Error of
        { code : int
        ; msg : string
        ; id : int option
        }
  [@@deriving sexp, compare, equal, yojson]

  (** Whether a websocket message is a response rather than a market event: an object with
      [result] or with [code] and [msg]. *)
  val is_response : Yojson.Safe.t -> bool
end
