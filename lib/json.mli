(** Opaque JSON values and small decoding helpers shared by the hand-written codecs. *)

open! Core

type t = Yojson.Safe.t [@@deriving sexp, compare, equal, yojson]

(** Raises [Ppx_yojson_conv_lib.Yojson_conv.Of_yojson_error]. *)
val error : string -> t -> 'a

(** [member json ~key] is the value of [key] if [json] is an object containing it. *)
val member : t -> key:string -> t option

(** Like [member] but raises if the key is missing. *)
val member_exn : t -> key:string -> t

(** [tag json ~key] reads a string-valued discriminator field, e.g. the event type ["e"]. *)
val tag : t -> key:string -> string

(** Decodes a JSON string with [of_wire]; [name] is used in error messages. *)
val enum_of_yojson : name:string -> of_wire:(string -> 'a option) -> t -> 'a

(** Integers that Binance sends as JSON strings, e.g. [leverage: "20"]. *)
module Int_string : sig
  type t = int [@@deriving sexp, compare, equal, yojson]
end

(** Booleans that Binance sends as JSON strings, e.g. [isAutoAddMargin: "false"] and the
    [reduceOnly] request parameter. *)
module Bool_string : sig
  type t = bool [@@deriving sexp, compare, equal, yojson]
end
