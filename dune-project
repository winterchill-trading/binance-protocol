(lang dune 3.17)
(name binance-protocol)
(generate_opam_files true)
(license MIT)
(maintainers "winterchill-trading")
(authors "winterchill-trading")
(source (github winterchill-trading/binance-protocol))
(package
 (name binance-protocol)
 (synopsis "Binance USD-M Futures wire types and JSON codecs")
 (depends
  (ocaml (>= 5.2))
  dune
  core
  cryptokit
  fixed-decimal
  exchange-core
  ppx_jane
  ppx_yojson_conv
  yojson))
