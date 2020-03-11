module Element.Input exposing (button)

import Elmy exposing (Attribute(..), ButtonConfig, Element(..))


button : List (Attribute msg) -> ButtonConfig msg -> Element msg
button =
    Button
