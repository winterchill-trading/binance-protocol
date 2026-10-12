open! Core

let sign ~secret ~query_string =
  Cryptokit.hash_string (Cryptokit.MAC.hmac_sha256 secret) query_string
  |> Cryptokit.transform_string (Cryptokit.Hexa.encode ())
;;

let signed_query ?recv_window ~secret ~timestamp params =
  let query_string =
    Query.encode
      (params
       @ List.filter_opt
           [ Option.map recv_window ~f:(fun w -> "recvWindow", Int.to_string w)
           ; Some ("timestamp", Int.to_string (Timestamp_ms.to_int timestamp))
           ])
  in
  query_string ^ "&signature=" ^ sign ~secret ~query_string
;;
