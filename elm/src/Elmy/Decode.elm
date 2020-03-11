module Elmy.Decode exposing (attribute, container, element, hAlign, length, list, string, unwrap, vAlign)

import Bytes.Decode as D exposing (Decoder)
import Elmy
    exposing
        ( Attribute(..)
        , ButtonConfig
        , Container(..)
        , Element(..)
        , HAlign(..)
        , ImageConfig
        , Length(..)
        , LinkConfig
        , VAlign(..)
        )
import Elmy.Spec exposing (Version(..), en)


unwrap : Decoder ( Version, Element msg )
unwrap =
    D.map2 Tuple.pair
        (D.map Version D.unsignedInt8)
        element


element : Decoder (Element msg)
element =
    let
        helper t =
            case t of
                0x00 ->
                    D.succeed None

                0x01 ->
                    D.map2 Element (list attribute) element

                0xA0 ->
                    D.map3 Container
                        container
                        (list attribute)
                        (list element)

                0xB0 ->
                    D.map Text string

                0xB1 ->
                    D.map2 Link (list attribute) <|
                        D.map3 LinkConfig
                            string
                            element
                            bool

                0xB2 ->
                    D.map2 Image (list attribute) <|
                        D.map2 ImageConfig
                            string
                            string

                0xB3 ->
                    D.map2 Button (list attribute) <|
                        D.map2 ButtonConfig
                            (D.unsignedInt8 |> D.andThen (\_ -> D.succeed Nothing))
                            element

                _ ->
                    D.fail
    in
    D.unsignedInt8 |> D.andThen helper


container : Decoder Container
container =
    let
        helper t =
            case t of
                0x00 ->
                    D.succeed Row

                0x01 ->
                    D.succeed WrappedRow

                0x02 ->
                    D.succeed Column

                _ ->
                    D.fail
    in
    D.unsignedInt8 |> D.andThen helper


attribute : Decoder (Attribute msg)
attribute =
    let
        helper t =
            case t of
                0x00 ->
                    D.map Width length

                0x01 ->
                    D.map Height length

                0x02 ->
                    D.map AlignX hAlign

                0x03 ->
                    D.map AlignY vAlign

                _ ->
                    D.fail
    in
    D.unsignedInt8 |> D.andThen helper


length : Decoder Length
length =
    let
        helper t =
            case t of
                0x00 ->
                    D.map Px pixels

                0x01 ->
                    D.succeed Content

                0x02 ->
                    D.map Fill D.unsignedInt8

                0x03 ->
                    D.map2 Min pixels length

                0x04 ->
                    D.map2 Max pixels length

                _ ->
                    D.fail
    in
    D.unsignedInt8 |> D.andThen helper


hAlign : Decoder HAlign
hAlign =
    let
        helper t =
            case t of
                0x00 ->
                    D.succeed Left

                0x01 ->
                    D.succeed CenterX

                0x02 ->
                    D.succeed Right

                _ ->
                    D.fail
    in
    D.unsignedInt8 |> D.andThen helper


vAlign : Decoder VAlign
vAlign =
    let
        helper t =
            case t of
                0x00 ->
                    D.succeed Top

                0x01 ->
                    D.succeed CenterY

                0x02 ->
                    D.succeed Bottom

                _ ->
                    D.fail
    in
    D.unsignedInt8 |> D.andThen helper


pixels : Decoder Int
pixels =
    D.unsignedInt16 en


string : Decoder String
string =
    D.unsignedInt32 en
        |> D.andThen D.string


list : Decoder a -> Decoder (List a)
list decoder =
    let
        listStep ( n, xs ) =
            if n <= 0 then
                D.succeed (D.Done <| List.reverse xs)

            else
                D.map (\x -> D.Loop ( n - 1, x :: xs )) decoder
    in
    D.unsignedInt16 en
        |> D.andThen (\size -> D.loop ( size, [] ) listStep)


bool : Decoder Bool
bool =
    let
        helper b =
            case b of
                0x00 ->
                    D.succeed False

                0x01 ->
                    D.succeed True

                _ ->
                    D.fail
    in
    D.unsignedInt8 |> D.andThen helper
