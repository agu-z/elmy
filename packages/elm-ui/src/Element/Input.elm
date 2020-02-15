module Element.Input exposing (button)

import UiAsm exposing (Attribute(..), ButtonConfig, Element(..))


button : List (Attribute msg) -> ButtonConfig msg -> Element msg
button =
    Button
