port module Ports exposing
    ( exit
    , onTick
    , stdin
    , stdout
    )


port stdin : (String -> msg) -> Sub msg


port stdout : String -> Cmd msg


port exit : Int -> Cmd msg


port onTick : (Float -> msg) -> Sub msg
