module Readme exposing (main)

import Ansi.Color
import Browser
import Layoutz
import Ports
import Task


main : Program () Model Msg
main =
    Platform.worker
        { init = init
        , update = update
        , subscriptions = subscriptions
        }


type alias Model =
    {}


init : () -> ( Model, Cmd Msg )
init () =
    render ( {}, Task.perform (\() -> Quit) (Task.succeed ()) )



-- Define layouts


t =
    Layoutz.withBorder Layoutz.BorderRound <|
        Layoutz.table [ "Name", "Role", "Status" ]
            [ [ Layoutz.text "Alice", Layoutz.text "Engineer", Layoutz.text "Online" ]
            , [ Layoutz.text "Eve", Layoutz.text "QA", Layoutz.text "Away" ]
            , [ Layoutz.ul [ Layoutz.text "Gegard", Layoutz.ul [ Layoutz.text "Mousasi", Layoutz.ul [ Layoutz.text "was a BAD man" ] ] ], Layoutz.text "Fighter", Layoutz.text "Nasty" ]
            ]



-- Nest, compose, combine them


d =
    Layoutz.layout
        [ Layoutz.center <|
            Layoutz.row
                [ Layoutz.withStyle Layoutz.StyleBold <| Layoutz.underlineColored "^" Ansi.Color.BrightMagenta <| Layoutz.text "Layoutz"
                , Layoutz.text "... A Small Demo (ちいさい)"
                ]
        , Layoutz.row
            [ Layoutz.withColor Ansi.Color.BrightBlue <| Layoutz.statusCard "Users" "1.2K"
            , Layoutz.withColor Ansi.Color.BrightGreen <| Layoutz.withBorder Layoutz.BorderDouble <| Layoutz.statusCard "API" "UP"
            , Layoutz.withColor Ansi.Color.BrightYellow <| Layoutz.withBorder Layoutz.BorderThick <| Layoutz.statusCard "CPU" "23%"
            , t
            , Layoutz.section "Pugilists"
                [ Layoutz.layout
                    [ Layoutz.keyValue [ ( "Kazushi", "Sakuraba" ), ( "Jet 李連杰", "Li" ), ( "Rory", "MacDonald" ) ]
                    , Layoutz.tightRow <|
                        List.map
                            (\i ->
                                let
                                    r =
                                        if i < 128 then
                                            i * 2

                                        else
                                            255

                                    g =
                                        if i < 128 then
                                            255

                                        else
                                            (255 - i) * 2

                                    b =
                                        if i > 128 then
                                            (i - 128) * 2

                                        else
                                            0
                                in
                                Layoutz.withColor (Ansi.Color.CustomTrueColor { red = r, green = g, blue = b }) <| Layoutz.text "█"
                            )
                            (0 :: List.range 12 255)
                    ]
                ]
            ]
        , Layoutz.row
            [ Layoutz.layout
                [ Layoutz.withColor Ansi.Color.BrightMagenta <|
                    Layoutz.withStyle (Layoutz.StyleCombined [ Layoutz.StyleReverse, Layoutz.StyleBold ]) <|
                        Layoutz.box "Wrapped"
                            [ Layoutz.wrap 20 "Where there is a will ... Water x Necessaries" ]
                , Layoutz.ol [ Layoutz.text "Arcole", Layoutz.text "Austerlitz", Layoutz.ol [ Layoutz.text "Iéna", Layoutz.ol [ Layoutz.text "Бородино" ] ] ]
                ]
            , Layoutz.margin "[Haskell!]"
                [ Layoutz.withColor Ansi.Color.Green <|
                    Layoutz.box "Deploy Status"
                        [ Layoutz.inlineBar "Build" 1.0
                        , Layoutz.inlineBar "Test" 0.8
                        , Layoutz.inlineBar "Deploy" 0.3
                        ]
                , Layoutz.withColor Ansi.Color.Cyan <|
                    Layoutz.tree "📁 Project"
                        [ Layoutz.branch "src"
                            [ Layoutz.leaf "main.hs"
                            , Layoutz.leaf "test.hs"
                            ]
                        ]
                ]
            ]
        ]


render : ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
render ( model, cmd ) =
    ( model
    , Cmd.batch
        [ d
            |> Layoutz.render
            |> Ports.stdout
        , cmd
        ]
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update Quit model =
    ( model, Ports.exit 0 )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


type Msg
    = Quit
