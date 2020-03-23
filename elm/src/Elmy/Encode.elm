module Elmy.Encode exposing (attribute, container, element, hAlign, length, list, string, vAlign, wrap)

import Array exposing (Array)
import Bytes.Encode as E exposing (Encoder)
import Elmy
    exposing
        ( Attribute(..)
        , Container(..)
        , Element(..)
        , HAlign(..)
        , Length(..)
        , VAlign(..)
        )
import Elmy.Spec exposing (Version(..), en)


wrap : ( Version, Element msg ) -> Encoder
wrap w =
    case w of
        ( Version v, el ) ->
            E.sequence
                -- HEADERS
                [ E.unsignedInt8 v

                -- BODY
                , element el Array.empty |> Tuple.first
                ]


element : Element msg -> Array msg -> ( Encoder, Array msg )
element e msgIndex =
    case e of
        None ->
            ( E.unsignedInt8 0x00, msgIndex )

        Element attrs child ->
            Tuple.mapFirst
                (\childElement ->
                    E.sequence
                        [ E.unsignedInt8 0x01
                        , list attribute attrs
                        , childElement
                        ]
                )
                (element child msgIndex)

        Container c attrs children ->
            let
                ( elements, newMl ) =
                    List.foldl
                        (\child ( recurringElements, recurringMsgIndex ) ->
                            Tuple.mapFirst (\x -> Array.push x recurringElements)
                                (element child recurringMsgIndex)
                        )
                        ( Array.empty, msgIndex )
                        children
            in
            ( E.sequence
                [ E.unsignedInt8 0xA0
                , container c
                , list attribute attrs
                , list identity <| Array.toList elements
                ]
            , newMl
            )

        Text txt ->
            ( E.sequence
                [ E.unsignedInt8 0xB0
                , string txt
                ]
            , msgIndex
            )

        Link attrs { url, label, newTab } ->
            Tuple.mapFirst
                (\labelElement ->
                    E.sequence
                        [ E.unsignedInt8 0xB1
                        , list attribute attrs
                        , string url
                        , labelElement
                        , bool newTab
                        ]
                )
                (element label msgIndex)

        Image attrs { src, description } ->
            ( E.sequence
                [ E.unsignedInt8 0xB2
                , list attribute attrs
                , string src
                , string description
                ]
            , msgIndex
            )

        Button attrs { onPress, label } ->
            let
                ( msgNumber, buttonMl ) =
                    case onPress of
                        Just msg ->
                            ( Array.length msgIndex + 1, Array.push msg msgIndex )

                        _ ->
                            ( 0, msgIndex )
            in
            Tuple.mapFirst
                (\labelElement ->
                    E.sequence
                        [ E.unsignedInt8 0xB3
                        , list attribute attrs
                        , E.unsignedInt16 en msgNumber
                        , labelElement
                        ]
                )
                (element label buttonMl)


container : Container -> Encoder
container c =
    E.unsignedInt8 <|
        case c of
            Row ->
                0x00

            WrappedRow ->
                0x01

            Column ->
                0x02


attribute : Attribute msg -> Encoder
attribute a =
    case a of
        Width l ->
            E.sequence
                [ E.unsignedInt8 0x00
                , length l
                ]

        Height l ->
            E.sequence
                [ E.unsignedInt8 0x01
                , length l
                ]

        AlignX x ->
            E.sequence [ E.unsignedInt8 0x02, hAlign x ]

        AlignY y ->
            E.sequence [ E.unsignedInt8 0x03, vAlign y ]

        _ ->
            E.unsignedInt8 0xFF


length : Length -> Encoder
length l =
    case l of
        Px px ->
            E.sequence
                [ E.unsignedInt8 0x00
                , pixels px
                ]

        Content ->
            E.unsignedInt8 0x01

        Fill portion ->
            E.sequence
                [ E.unsignedInt8 0x02
                , E.unsignedInt8 portion
                ]

        Min min sublen ->
            E.sequence
                [ E.unsignedInt8 0x03
                , pixels min
                , length sublen
                ]

        Max max sublen ->
            E.sequence
                [ E.unsignedInt8 0x04
                , pixels max
                , length sublen
                ]


hAlign : HAlign -> Encoder
hAlign x =
    E.unsignedInt8 <|
        case x of
            Left ->
                0x00

            CenterX ->
                0x01

            Right ->
                0x02


vAlign : VAlign -> Encoder
vAlign y =
    E.unsignedInt8 <|
        case y of
            Top ->
                0x00

            CenterY ->
                0x01

            Bottom ->
                0x02


pixels : Int -> Encoder
pixels =
    E.unsignedInt16 en


string : String -> Encoder
string str =
    E.sequence
        [ E.unsignedInt32 en <| E.getStringWidth str
        , E.string str
        ]


list : (a -> Encoder) -> List a -> Encoder
list enc xs =
    E.sequence
        [ E.unsignedInt16 en <| List.length xs
        , E.sequence <| List.map enc xs
        ]


bool : Bool -> Encoder
bool b =
    E.unsignedInt8 <|
        if b then
            0x01

        else
            0x00
