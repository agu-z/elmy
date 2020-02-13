module Spec exposing (attribute, container, element, length, wrap)

import Bytes exposing (Bytes)
import Bytes.Decode as Decode
import Bytes.Encode as Encode
import Expect exposing (Expectation)
import Hex.Convert as Hex
import Test exposing (Test, describe, test)
import UiAsm exposing (Attribute(..), Container(..), Element(..), Length(..))
import UiAsm.Decode as UDecode
import UiAsm.Encode as UEncode
import UiAsm.Spec exposing (Version(..))


wrap : Test
wrap =
    test "wrap" <|
        testFormat UEncode.wrap UDecode.unwrap ( Version 0, Element [] (Text "Hi") )


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
            elementFormat (Element [ Width <| Fill 1 ] (Text "Hi"))
        , test "Container" <|
            elementFormat (Container Row [ Width <| Px 300 ] [ Element [] (Text "Hello"), Text "World" ])
        , test "Text" <|
            elementFormat (Text "Hello World")
        , test "Link" <|
            elementFormat (Link [ Height <| Px 200 ] { url = "https://example.com", label = Text "Click Here", newTab = False })
        , test "Link (new tab)" <|
            elementFormat (Link [ Width <| Fill 2 ] { url = "https://example.com", label = Text "Click Here", newTab = True })
        , test "Image" <|
            elementFormat (Image [ Width <| Px 100 ] { src = "https://example.com/cat.jpg", description = "A photo of a cat" })
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


attribute : Test
attribute =
    let
        attributeFormat =
            testFormat UEncode.attribute UDecode.attribute
    in
    describe "Attribute(..)"
        [ test "Width" <| attributeFormat (Width <| Px 100)
        , test "Height" <| attributeFormat (Height <| Fill 1)
        ]


length : Test
length =
    let
        lengthFormat =
            testFormat UEncode.length UDecode.length
    in
    describe "Length(..)"
        [ test "Px" <| lengthFormat (Px 100)
        , test "Content" <| lengthFormat Content
        , test "Fill" <| lengthFormat (Fill 2)
        , test "Min" <| lengthFormat (Min 300 (Fill 3))
        , test "Max" <| lengthFormat (Max 400 Content)
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
