module Spinner exposing (..)

{-| Spinner demo - Shows different spinner animations

Press any key to advance the animation frame
Press ESC to quit

-}

import Ansi
import Ansi.Color
import Ansi.Cursor
import Browser
import Layoutz
import Ports


main : Program () Model Msg
main =
    Platform.worker
        { init = init
        , update = update
        , subscriptions = subscriptions
        }


type alias Model =
    { frameCount : Float
    , tick : Float
    }


init : () -> ( Model, Cmd Msg )
init () =
    render
        ( { frameCount = 0
          , tick = 0
          }
        , Cmd.none
        )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ Ports.onTick Tick
        , Ports.stdin
            (\input ->
                case input of
                    -- ESC
                    "\u{001B}" ->
                        Quit

                    -- Ctrl+C
                    "\u{0003}" ->
                        Quit

                    _ ->
                        NoOp
            )
        ]


type Msg
    = Quit
    | NoOp
    | Tick Float


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        Quit ->
            ( model, Ports.exit 0 )

        Tick time ->
            if model.tick == 0 then
                ( { model
                    | tick = time / 100
                  }
                , Cmd.none
                )

            else
                render
                    ( { model
                        | frameCount = model.frameCount + (time / 100 - model.tick)
                        , tick = time / 100
                      }
                    , Cmd.none
                    )


render : ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
render ( model, cmd ) =
    let
        frame =
            floor model.frameCount
    in
    ( model
    , Cmd.batch
        [ Layoutz.layout
            [ Layoutz.section "Spinner Styles"
                [ Layoutz.text "Spinners animate automatically!"
                , Layoutz.text ""
                , Layoutz.row [ Layoutz.text "Dots:   ", Layoutz.spinner "Loading..." frame Layoutz.SpinnerDots ]
                , Layoutz.row [ Layoutz.text "Line:   ", Layoutz.spinner "Processing" frame Layoutz.SpinnerLine ]
                , Layoutz.row [ Layoutz.text "Clock:  ", Layoutz.spinner "Working" frame Layoutz.SpinnerClock ]
                , Layoutz.row [ Layoutz.text "Bounce: ", Layoutz.spinner "Thinking" frame Layoutz.SpinnerBounce ]
                ]
            , Layoutz.br
            , Layoutz.section "Examples"
                [ Layoutz.text "With colors:"
                , Layoutz.withColor Ansi.Color.Green <| Layoutz.spinner "Success!" frame Layoutz.SpinnerDots
                , Layoutz.withColor Ansi.Color.Yellow <| Layoutz.spinner "Warning" frame Layoutz.SpinnerLine
                , Layoutz.withColor Ansi.Color.Red <| Layoutz.spinner "Error" frame Layoutz.SpinnerBounce
                , Layoutz.br
                , Layoutz.text "Without labels:"
                , Layoutz.row
                    [ Layoutz.spinner "" frame Layoutz.SpinnerDots
                    , Layoutz.text " "
                    , Layoutz.spinner "" frame Layoutz.SpinnerLine
                    , Layoutz.text " "
                    , Layoutz.spinner "" frame Layoutz.SpinnerClock
                    , Layoutz.text " "
                    , Layoutz.spinner "" frame Layoutz.SpinnerBounce
                    ]
                ]
            , Layoutz.br
            , Layoutz.text <| "Frame: " ++ String.fromInt frame
            , Layoutz.text "Press ESC to quit"
            ]
            |> Layoutz.render
            |> (\rendered -> Ansi.Cursor.hide ++ Ansi.clearScreen ++ rendered)
            |> Ports.stdout
        , cmd
        ]
    )
