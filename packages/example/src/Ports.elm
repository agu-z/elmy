port module Ports exposing (render)

import Array


port render : Array.Array Int -> Cmd msg
