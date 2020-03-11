module Elmy.Spec exposing (Version(..), en, version)

import Bytes exposing (Endianness(..))


type Version
    = Version Int


en : Endianness
en =
    BE


version : Version
version =
    Version 0
