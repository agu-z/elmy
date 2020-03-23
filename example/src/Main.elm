module Main exposing (main)

import Element exposing (column, text)
import Element.Input exposing (button)
import Elmy exposing (Element(..))
import Elmy.Remote exposing (RemoteElement, remoteElement)
import Ports


type alias Flags =
    ()


type alias Model =
    Int


type Msg
    = Increment
    | Decrement


init : Flags -> ( Model, Cmd Msg )
init _ =
    ( 1, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg val =
    case msg of
        Decrement ->
            ( val - 1, Cmd.none )

        Increment ->
            ( val + 1, Cmd.none )


view : Model -> Element Msg
view val =
    column []
        [ button [] { onPress = Just Decrement, label = text "Decrement" }
        , text <| String.fromInt val
        , button [] { onPress = Just Increment, label = text "Increment" }
        ]


main : RemoteElement Flags Model Msg
main =
    remoteElement
        { init = init
        , update = update
        , view = view
        , tick = Ports.tick
        , msg = Ports.msg
        }
