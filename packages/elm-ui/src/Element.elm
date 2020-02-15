module Element exposing (row, text)

import UiAsm exposing (Attribute(..), Container(..), Element(..))


text : String -> Element msg
text =
    Text


row : List (Attribute msg) -> List (Element msg) -> Element msg
row =
    Container Row
