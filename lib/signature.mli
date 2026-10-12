(** HMAC-SHA256 request signing for [TRADE] and [USER_DATA] endpoints. Pure: the caller
    supplies [timestamp] (and optionally [recvWindow]) and sends the result with the
    [X-MBX-APIKEY] header. RSA and Ed25519 keys are not supported. *)

open! Core

(** Lowercase hex HMAC-SHA256 of [query_string] keyed by [secret]. [query_string] is the
    exact query string followed by the exact request body, as sent. *)
val sign : secret:string -> query_string:string -> string

(** [params] followed by [timestamp], [recvWindow] (if given) and [signature], encoded
    with {!Query.encode}; the signature covers everything before it. *)
val signed_query
  :  ?recv_window:int
  -> secret:string
  -> timestamp:Timestamp_ms.t
  -> Query.t
  -> string
