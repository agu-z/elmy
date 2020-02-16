module Element exposing (column, row, text, wrappedRow)

import UiAsm exposing (Attribute(..), Container(..), Element(..))


text : String -> Element msg
text =
    Text


row : List (Attribute msg) -> List (Element msg) -> Element msg
row =
    Container Row


wrappedRow : List (Attribute msg) -> List (Element msg) -> Element msg
wrappedRow =
    Container WrappedRow


column : List (Attribute msg) -> List (Element msg) -> Element msg
column =
    Container Column
