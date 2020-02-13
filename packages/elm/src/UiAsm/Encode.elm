module UiAsm.Encode exposing (container, element, list, string)

import Bytes.Encode as E exposing (Encoder)
import UiAsm exposing (Container(..), Element(..))
import UiAsm.Spec exposing (en)


wrap : Element msg -> Encoder
wrap el =
    E.sequence
        -- HEADERS
        [ E.unsignedInt8 0x00 -- version 0

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
                , element child
                ]

        Container c attrs children ->
            E.sequence
                [ E.unsignedInt8 0xA0
                , container c
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
                , string url
                , element label
                , bool newTab
                ]

        _ ->
            E.unsignedInt8 0x00


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
