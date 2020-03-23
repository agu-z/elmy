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


type alias RemoteModel model msg =
    { model : model
    , msgIndex : Array msg
    }


type alias RemoteMsg =
    Int


type alias RemoteElement flags model msg =
    Program flags (RemoteModel model msg) RemoteMsg


remoteElement :
    { init : flags -> ( model, Cmd msg )
    , update : msg -> model -> ( model, Cmd msg )
    , view : model -> Element msg
    , tick : Array Int -> Cmd RemoteMsg
    , msg : (Int -> RemoteMsg) -> Sub RemoteMsg
    }
    -> RemoteElement flags model msg
remoteElement element =
    let
        tick : ( model, Cmd msg ) -> ( RemoteModel model msg, Cmd RemoteMsg )
        tick ( model, _ ) =
            let
                ( viewElement, msgIndex ) =
                    UEncode.element (element.view model) Array.empty
            in
            ( RemoteModel model msgIndex
            , Cmd.batch
                [ -- TODO: Deal with custom commands
                  element.tick <|
                    bytesToIntArray (Encode.encode viewElement)
                ]
            )

        init : flags -> ( RemoteModel model msg, Cmd RemoteMsg )
        init =
            tick << element.init

        update : RemoteMsg -> RemoteModel model msg -> ( RemoteModel model msg, Cmd RemoteMsg )
        update msgNumber remoteModel =
            case Array.get (msgNumber - 1) remoteModel.msgIndex of
                Just msg ->
                    tick <| element.update msg remoteModel.model

                Nothing ->
                    ( remoteModel, Cmd.none )

        subscriptions : RemoteModel model msg -> Sub RemoteMsg
        subscriptions _ =
            element.msg identity
    in
    worker
        { init = init
        , update = update
        , subscriptions = subscriptions
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
