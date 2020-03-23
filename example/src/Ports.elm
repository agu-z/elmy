port module Ports exposing (msg, tick)

import Array


port tick : Array.Array Int -> Cmd msg


port msg : (Int -> msg) -> Sub msg
