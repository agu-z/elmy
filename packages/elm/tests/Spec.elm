module Spec exposing (container, element)

import Bytes exposing (Bytes)
import Bytes.Decode as Decode
import Bytes.Encode as Encode
import Expect exposing (Expectation)
import Hex.Convert as Hex
import Test exposing (Test, describe, test)
import UiAsm exposing (Container(..), Element(..))
import UiAsm.Decode as UDecode
import UiAsm.Encode as UEncode


element : Test
element =
    let
        elementFormat =
            testFormat UEncode.element UDecode.element
    in
    describe "Element(..)"
        [ test "None" <|
            elementFormat None
        , test "Element" <|
            elementFormat (Element [] (Text "Hi"))
        , test "Container" <|
            elementFormat (Container Row [] [ Element [] (Text "Hello"), Text "World" ])
        , test "Text" <|
            elementFormat (Text "Hello World")
        , test "Link" <|
            elementFormat (Link [] { url = "https://example.com", label = Text "Click Here", newTab = False })
        , test "Link (new tab)" <|
            elementFormat (Link [] { url = "https://example.com", label = Text "Click Here", newTab = True })
        , test "Image" <|
            elementFormat (Image [] { src = "https://example.com/cat.jpg", description = "A photo of a cat" })
        ]


container : Test
container =
    let
        containerFormat =
            testFormat UEncode.container UDecode.container
    in
    describe "Container(..)"
        [ test "Row" <| containerFormat Row
        , test "WrappedRow" <| containerFormat WrappedRow
        , test "Column" <| containerFormat Column
        ]


logBytes : String -> Bytes -> Bytes
logBytes x b =
    let
        _ =
            Debug.log x (Hex.toString b |> Hex.blocks 2 |> String.join " ")
    in
    b


testFormat : (a -> Encode.Encoder) -> Decode.Decoder a -> a -> (() -> Expectation)
testFormat encoder decoder value =
    value
        |> encoder
        |> Encode.encode
        |> logBytes (Debug.toString value)
        |> Decode.decode decoder
        |> (\v -> \_ -> Expect.equal v (Just value))
