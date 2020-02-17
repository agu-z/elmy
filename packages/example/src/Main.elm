module Main exposing (main)

import Element exposing (column, text)
import Element.Input exposing (button)
import Ports exposing (render)
import UiAsm exposing (Element(..))
import UiAsm.Remote exposing (remoteElement)


view : Element msg
view =
    column []
        [ button [] { onPress = Nothing, label = text "Decrement" }
        , text "0"
        , button [] { onPress = Nothing, label = text "Increment" }
        ]


main : Program () () msg
main =
    remoteElement
        { view = view
        , render = render
        }
