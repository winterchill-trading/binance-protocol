(** Dimensionless or asset-denominated decimals that are neither prices, sizes nor USD:
    funding and interest rates, commissions (in [commissionAsset]), filter multipliers.
    Encoded as decimal strings; at most 8 fractional digits are kept. *)

open! Core
include Fixed_decimal.S
