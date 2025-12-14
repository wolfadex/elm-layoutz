port module Ports exposing
    ( exit
    , stdin
    , stdout
    )


port stdin : (String -> msg) -> Sub msg


port stdout : String -> Cmd msg


port exit : Int -> Cmd msg
