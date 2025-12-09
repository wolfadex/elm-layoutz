port module Counter exposing (main)

import Browser
import Layoutz


main : Program () Model Msg
main =
    Platform.worker
        { init = init
        , update = update
        , subscriptions = subscriptions
        }


type alias Model =
    { count : Int }


init : () -> ( Model, Cmd Msg )
init () =
    render ( { count = 0 }, Cmd.none )


port stdin : (String -> msg) -> Sub msg


port stdout : String -> Cmd msg


port exit : Int -> Cmd msg


subscriptions : Model -> Sub Msg
subscriptions _ =
    stdin
        (\input ->
            case input of
                "+" ->
                    Increment

                "-" ->
                    Decrement

                -- ESC
                "\u{001B}" ->
                    Quit

                -- Ctrl+C
                "\u{0003}" ->
                    Quit

                _ ->
                    NoOp
        )


type Msg
    = Quit
    | NoOp
    | Increment
    | Decrement


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        Quit ->
            ( model, exit 0 )

        Increment ->
            render ( { model | count = model.count + 1 }, Cmd.none )

        Decrement ->
            render ( { model | count = model.count - 1 }, Cmd.none )


render : ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
render ( model, cmd ) =
    ( model
    , Cmd.batch
        [ Layoutz.layout
            [ Layoutz.section "Counter"
                [ Layoutz.text <| "Count: " ++ String.fromInt model.count
                ]
            , Layoutz.br
            , Layoutz.ul
                [ Layoutz.text "Press '+' or '-'"
                , Layoutz.text "Press ESC to quit"
                ]
            ]
            |> Layoutz.render
            |> stdout
        , cmd
        ]
    )
