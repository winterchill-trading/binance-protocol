(** Response of [POST] and [PUT /fapi/v1/listenKey]: [{"listenKey": "pqia91ma..."}]. A key
    is valid for 60 minutes after creation or the last keepalive. *)

open! Core

type t = { listen_key : string } [@@deriving sexp, compare, equal, yojson]
