module UiAsm.Decode exposing (container, element, list, string)

import Bytes exposing (Endianness(..))
import Bytes.Decode as D exposing (Decoder)
import UiAsm exposing (Container(..), Element(..), ImageConfig, LinkConfig)


element : Decoder (Element msg)
element =
    let
        helper t =
            case t of
                0x00 ->
                    D.succeed None

                0x01 ->
                    D.map (Element []) element

                0xA0 ->
                    D.map3 Container
                        container
                        (D.succeed [])
                        (list element)

                0xB0 ->
                    D.map Text string

                0xB1 ->
                    D.map (Link []) <|
                        D.map3 LinkConfig
                            string
                            element
                            bool

                0xB2 ->
                    D.map (Image []) <|
                        D.map2 ImageConfig
                            string
                            string

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


string : Decoder String
string =
    D.unsignedInt32 BE
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
    D.unsignedInt16 BE
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
