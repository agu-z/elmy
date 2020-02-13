module UiAsm.Encode exposing (attribute, container, element, length, list, string, wrap)

import Bytes.Encode as E exposing (Encoder)
import UiAsm exposing (Attribute(..), Container(..), Element(..), Length(..))
import UiAsm.Spec exposing (Version(..), en)


wrap : ( Version, Element msg ) -> Encoder
wrap w =
    case w of
        ( Version v, el ) ->
            E.sequence
                -- HEADERS
                [ E.unsignedInt8 v

                -- BODY
                , element el
                ]


element : Element msg -> Encoder
element e =
    case e of
        None ->
            E.unsignedInt8 0x00

        Element attrs child ->
            E.sequence
                [ E.unsignedInt8 0x01
                , list attribute attrs
                , element child
                ]

        Container c attrs children ->
            E.sequence
                [ E.unsignedInt8 0xA0
                , container c
                , list attribute attrs
                , list element children
                ]

        Text txt ->
            E.sequence
                [ E.unsignedInt8 0xB0
                , string txt
                ]

        Link attrs { url, label, newTab } ->
            E.sequence
                [ E.unsignedInt8 0xB1
                , list attribute attrs
                , string url
                , element label
                , bool newTab
                ]

        Image attrs { src, description } ->
            E.sequence
                [ E.unsignedInt8 0xB2
                , list attribute attrs
                , string src
                , string description
                ]


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

        _ ->
            E.unsignedInt8 0x00


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
