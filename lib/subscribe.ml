open! Core
open Ppx_yojson_conv_lib.Yojson_conv.Primitives

module Method = struct
  type t =
    | Subscribe
    | Unsubscribe
    | List_subscriptions
  [@@deriving sexp, compare, equal, hash, enumerate]

  let to_wire = function
    | Subscribe -> "SUBSCRIBE"
    | Unsubscribe -> "UNSUBSCRIBE"
    | List_subscriptions -> "LIST_SUBSCRIPTIONS"
  ;;

  let of_wire s = List.find all ~f:(fun t -> String.equal (to_wire t) s)
  let yojson_of_t t : Yojson.Safe.t = `String (to_wire t)
  let t_of_yojson = Json.enum_of_yojson ~name:"Subscribe.Method" ~of_wire
end

module Request = struct
  type t =
    { method_ : Method.t [@key "method"]
    ; params : Stream_name.t list [@default []] [@yojson_drop_if List.is_empty]
    ; id : int
    }
  [@@deriving sexp, compare, equal, yojson]
end

module Response = struct
  type t =
    | Result of
        { result : Json.t
        ; id : int
        }
    | Error of
        { code : int
        ; msg : string
        ; id : int option
        }
  [@@deriving sexp, compare, equal]

  module Result_wire = struct
    type t =
      { result : Json.t
      ; id : int
      }
    [@@deriving yojson] [@@yojson.allow_extra_fields]
  end

  module Error_wire = struct
    type t =
      { code : int
      ; msg : string
      ; id : int option [@default None] [@yojson_drop_if Option.is_none]
      }
    [@@deriving yojson] [@@yojson.allow_extra_fields]
  end

  let yojson_of_t = function
    | Result { result; id } -> Result_wire.yojson_of_t { result; id }
    | Error { code; msg; id } -> Error_wire.yojson_of_t { code; msg; id }
  ;;

  let t_of_yojson json =
    match Json.member json ~key:"code" with
    | Some _ ->
      let { Error_wire.code; msg; id } = Error_wire.t_of_yojson json in
      Error { code; msg; id }
    | None ->
      let { Result_wire.result; id } = Result_wire.t_of_yojson json in
      Result { result; id }
  ;;

  let is_response json =
    Option.is_some (Json.member json ~key:"result")
    || (Option.is_some (Json.member json ~key:"code")
        && Option.is_some (Json.member json ~key:"msg"))
  ;;
end
