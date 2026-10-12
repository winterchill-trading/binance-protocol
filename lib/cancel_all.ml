open! Core
open Ppx_yojson_conv_lib.Yojson_conv.Primitives

module Request = struct
  type t = { symbol : Symbol.t } [@@deriving sexp, compare, equal]

  let to_params { symbol } = [ "symbol", Symbol.to_string symbol ]
end

module Response = struct
  type t =
    { code : int
    ; msg : string
    }
  [@@deriving sexp, compare, equal, yojson] [@@yojson.allow_extra_fields]

  let is_success t = t.code = 200
end
