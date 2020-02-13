module UiAsm exposing
    ( Attribute(..)
    , BackgroundRepeat(..)
    , BorderRadiusEach
    , BorderWidthEach
    , Color(..)
    , Container(..)
    , Cursor(..)
    , Element(..)
    , Gradient
    , HAlign(..)
    , ImageConfig
    , Length(..)
    , LineStyle(..)
    , LinkConfig
    , PaddingEach
    , Spacing(..)
    , VAlign(..)
    )


type Element msg
    = None
    | Element (List (Attribute msg)) (Element msg)
    | Container Container (List (Attribute msg)) (List (Element msg))
    | Text String
    | Link (List (Attribute msg)) (LinkConfig msg)
    | Image (List (Attribute msg)) ImageConfig


type Container
    = Row
    | WrappedRow
    | Column


type Attribute msg
    = Width Length
    | Height Length
    | AlignX HAlign
    | AlignY VAlign
    | Padding PaddingEach
    | Spacing Spacing
    | Alpha Float
    | BackgroundColor Color
    | BackgroundGradient Gradient
    | BackgroundImage BackgroundRepeat String
    | BorderColor Color
    | BorderWidth BorderWidthEach
    | BorderStyle LineStyle
    | BorderRadius BorderRadiusEach
    | MoveX Float
    | MoveY Float
    | Rotate Float
    | Scale Float
    | Cursor Cursor
    | FontColor Color
    | FontSize Int


type Length
    = Px Int
    | Content
    | Fill Int
    | Min Int Length
    | Max Int Length


type HAlign
    = Left
    | CenterX
    | Right


type VAlign
    = Top
    | CenterY
    | Bottom


type alias PaddingEach =
    { top : Int
    , right : Int
    , bottom : Int
    , left : Int
    }


type Spacing
    = SpaceEvenly
    | SpaceXY Int Int


type Color
    = Rgba Float Float Float Float


type alias Gradient =
    { angle : Float
    , steps : List Color
    }


type BackgroundRepeat
    = Cropped
    | Uncropped
    | Tiled Bool Bool


type alias BorderWidthEach =
    { top : Int
    , right : Int
    , bottom : Int
    , left : Int
    }


type LineStyle
    = Solid
    | Dashed
    | Dotted


type alias BorderRadiusEach =
    { topLeft : Int
    , topRight : Int
    , bottomLeft : Int
    , bottomRight : Int
    }


type Cursor
    = DefaultCursor
    | Pointer


type alias LinkConfig msg =
    { url : String
    , label : Element msg
    , newTab : Bool
    }


type alias ImageConfig =
    { src : String
    , description : String
    }
