open! Core

type t = Yojson.Safe.t

let sexp_of_t t = Sexp.Atom (Yojson.Safe.to_string t)

let t_of_sexp = function
  | Sexp.Atom s -> Yojson.Safe.from_string s
  | sexp -> of_sexp_error "Json.t_of_sexp: atom expected" sexp
;;

let compare a b = String.compare (Yojson.Safe.to_string a) (Yojson.Safe.to_string b)
let equal = Yojson.Safe.equal
let yojson_of_t = Fn.id
let t_of_yojson = Fn.id
let error msg t = Ppx_yojson_conv_lib.Yojson_conv.of_yojson_error msg t

let member (t : t) ~key =
  match t with
  | `Assoc fields -> List.Assoc.find fields key ~equal:String.equal
  | _ -> None
;;

let member_exn t ~key =
  match member t ~key with
  | Some v -> v
  | None -> error (sprintf "missing field %S" key) t
;;

let tag t ~key =
  match member_exn t ~key with
  | `String s -> s
  | _ -> error (sprintf "field %S must be a string" key) t
;;

let with_tag (t : t) ~key ~value : t =
  match t with
  | `Assoc fields -> `Assoc ((key, `String value) :: fields)
  | _ -> error "with_tag: object expected" t
;;

let enum_of_yojson ~name ~of_wire (json : t) =
  match json with
  | `String s ->
    (match of_wire s with
     | Some v -> v
     | None -> error (sprintf "%s: unknown value %S" name s) json)
  | _ -> error (sprintf "%s: string expected" name) json
;;

module Int_string = struct
  type t = int [@@deriving sexp, compare, equal]

  let yojson_of_t t : Yojson.Safe.t = `String (Int.to_string t)

  let t_of_yojson (json : Yojson.Safe.t) =
    match json with
    | `String s ->
      (match Int.of_string_opt s with
       | Some i -> i
       | None -> error "Int_string: integer string expected" json)
    | `Int i -> i
    | _ -> error "Int_string: string expected" json
  ;;
end

module Bool_string = struct
  type t = bool [@@deriving sexp, compare, equal]

  let yojson_of_t t : Yojson.Safe.t = `String (Bool.to_string t)

  let t_of_yojson (json : Yojson.Safe.t) =
    match json with
    | `String "true" -> true
    | `String "false" -> false
    | `Bool b -> b
    | _ -> error "Bool_string: \"true\" or \"false\" expected" json
  ;;
end
