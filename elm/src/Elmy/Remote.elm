module Elmy.Remote exposing
    ( RemoteElement
    , bytesToIntArray
    , remoteElement
    )

import Array exposing (Array)
import Bytes exposing (Bytes)
import Bytes.Decode as Decode
import Bytes.Encode as Encode
import Elmy exposing (Element)
import Elmy.Encode as UEncode
import Platform exposing (Program, worker)


type alias RemoteElement msg =
    { view : Element msg
    , render : Array Int -> Cmd msg
    }


remoteElement : RemoteElement msg -> Program () () msg
remoteElement { view, render } =
    worker
        { init = \_ -> ( (), render <| bytesToIntArray (Encode.encode <| UEncode.element view) )
        , update = \_ _ -> ( (), Cmd.none )
        , subscriptions = \_ -> Sub.none
        }


bytesToIntArray : Bytes -> Array Int
bytesToIntArray bytes =
    let
        step ( n, xs ) =
            if n <= 0 then
                Decode.succeed (Decode.Done xs)

            else
                Decode.map (\x -> Decode.Loop ( n - 1, Array.push x xs )) Decode.unsignedInt8
    in
    bytes
        |> Decode.decode (Decode.loop ( Bytes.width bytes, Array.empty ) step)
        |> Maybe.withDefault Array.empty
