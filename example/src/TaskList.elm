module TaskList exposing (main)

{-| Interactive Task List Demo - Navigate, complete, and add tasks with progress tracking

  - Navigate with Arrow Keys or W/S
  - Press Enter to start a task (shows progress bar and spinner)
  - Press any key to advance progress while task is running
  - Press 'A' to add a new task (type name, then digits for duration)
  - Press Enter/Tab to confirm new task, ESC to cancel
  - Press ESC to quit

-}

import Ansi
import Ansi.Color
import Ansi.Cursor
import Ansi.Decode
import Browser
import Json.Decode
import Layoutz
import Ports
import Set exposing (Set)


main : Program () Model Msg
main =
    Platform.worker
        { init = init
        , update = update
        , subscriptions = subscriptions
        }


type alias Model =
    { tasks : List String
    , selected : Int
    , completed : Set Int
    , spinFrame : Int
    , addingTask : Bool
    , newTaskName : String
    , newTaskDuration : String
    , taskDurations : List ( String, Int ) -- (task name, duration in steps)
    , isLoading : Bool
    , loadProgress : Int
    , loadingTaskIdx : Int
    }


init : () -> ( Model, Cmd Msg )
init () =
    render
        ( { tasks = List.map Tuple.first initialTasks
          , selected = 0
          , completed = Set.empty
          , spinFrame = 0
          , addingTask = False
          , newTaskName = ""
          , newTaskDuration = ""
          , taskDurations = initialTasks
          , isLoading = False
          , loadProgress = 0
          , loadingTaskIdx = -1
          }
        , Cmd.none
        )


initialTasks : List ( String, Int )
initialTasks =
    [ ( "Process data", 15 )
    , ( "Generate reports", 20 )
    , ( "Backup files", 12 )
    , ( "Sync with server", 18 )
    , ( "Clean temp files", 8 )
    , ( "Update documentation", 10 )
    ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ if model.isLoading then
            Ports.onTick (\_ -> AdvanceProgress)

          else
            Sub.none
        , Ports.stdin
            (\input ->
                case input of
                    -- Ctrl+C
                    "\u{0003}" ->
                        Quit

                    _ ->
                        if model.isLoading then
                            NoOp

                        else
                        -- case Json.Decode.decodeString Ansi.Decode.decodeKey input of
                        --     Err _ ->
                        --         NoOp
                        --     Ok key ->
                        if
                            model.addingTask
                        then
                            case input of
                                "\n" ->
                                    ConfirmTask

                                "\u{000D}" ->
                                    ConfirmTask

                                "\t" ->
                                    ConfirmTask

                                "\u{001B}" ->
                                    CancelAdd

                                "\u{007F}" ->
                                    DeleteChar

                                c ->
                                    if c >= "a" && c <= "z" || c >= "A" && c <= "Z" || c == " " then
                                        TypeChar c

                                    else if c >= "0" && c <= "9" then
                                        TypeDigit c

                                    else
                                        NoOp

                        else
                            case input of
                                "w" ->
                                    MoveUp

                                "W" ->
                                    MoveUp

                                "s" ->
                                    MoveDown

                                "S" ->
                                    MoveDown

                                "\n" ->
                                    StartTask

                                "\u{000D}" ->
                                    StartTask

                                "a" ->
                                    ToggleAddTask

                                "A" ->
                                    ToggleAddTask

                                _ ->
                                    if Ansi.Decode.isDownArrow input then
                                        MoveDown

                                    else if Ansi.Decode.isUpArrow input then
                                        MoveUp

                                    else
                                        NoOp
            )
        ]


type Msg
    = Quit
    | NoOp
    | MoveUp
    | MoveDown
    | StartTask
    | AdvanceProgress
    | ToggleAddTask
    | TypeChar String
    | TypeDigit String
    | DeleteChar
    | ConfirmTask
    | CancelAdd


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        Quit ->
            ( model, Ports.exit 0 )

        MoveUp ->
            if not model.addingTask && not model.isLoading then
                let
                    newSelected =
                        if model.selected > 0 then
                            model.selected - 1

                        else
                            List.length model.tasks - 1
                in
                render ( { model | selected = newSelected }, Cmd.none )

            else
                ( model, Cmd.none )

        MoveDown ->
            if not model.addingTask && not model.isLoading then
                let
                    newSelected =
                        if model.selected < List.length model.tasks - 1 then
                            model.selected + 1

                        else
                            0
                in
                render ( { model | selected = newSelected }, Cmd.none )

            else
                ( model, Cmd.none )

        StartTask ->
            if not model.addingTask && not model.isLoading && not (Set.member model.selected model.completed) then
                render
                    ( { model
                        | isLoading = True
                        , loadProgress = 0
                        , loadingTaskIdx = model.selected
                        , spinFrame = 0
                        , addingTask = False
                      }
                    , Cmd.none
                    )

            else
                ( model, Cmd.none )

        AdvanceProgress ->
            if model.isLoading then
                let
                    taskName =
                        model.tasks
                            |> List.drop model.loadingTaskIdx
                            |> List.head
                            |> Maybe.withDefault ""

                    duration =
                        List.filter (\( n, _ ) -> n == taskName) model.taskDurations
                            |> List.head
                            |> Maybe.map Tuple.second
                            |> Maybe.withDefault 0

                    newProgress =
                        model.loadProgress + 1
                in
                render
                    ( if newProgress >= duration then
                        { model
                            | isLoading = False
                            , loadProgress = 0
                            , completed = Set.insert model.loadingTaskIdx model.completed
                            , spinFrame = model.spinFrame + 1
                        }

                      else
                        { model
                            | loadProgress = newProgress
                            , spinFrame = model.spinFrame + 1
                        }
                    , Cmd.none
                    )

            else
                ( model, Cmd.none )

        ToggleAddTask ->
            if not model.isLoading then
                render
                    ( { model
                        | addingTask = True
                        , newTaskName = ""
                        , newTaskDuration = ""
                        , isLoading = False
                      }
                    , Cmd.none
                    )

            else
                ( model, Cmd.none )

        CancelAdd ->
            render
                ( { model
                    | addingTask = False
                    , newTaskName = ""
                    , newTaskDuration = ""
                    , isLoading = False
                  }
                , Cmd.none
                )

        TypeChar c ->
            if model.addingTask then
                render ( { model | newTaskName = model.newTaskName ++ c }, Cmd.none )

            else
                ( model, Cmd.none )

        TypeDigit d ->
            if model.addingTask then
                render ( { model | newTaskDuration = model.newTaskDuration ++ d }, Cmd.none )

            else
                ( model, Cmd.none )

        DeleteChar ->
            if model.addingTask then
                if not (String.isEmpty model.newTaskDuration) then
                    render ( { model | newTaskDuration = String.dropRight 1 model.newTaskDuration }, Cmd.none )

                else if not (String.isEmpty model.newTaskName) then
                    render ( { model | newTaskName = String.dropRight 1 model.newTaskName }, Cmd.none )

                else
                    ( model, Cmd.none )

            else
                ( model, Cmd.none )

        ConfirmTask ->
            if model.addingTask && not (String.isEmpty model.newTaskName) && not (String.isEmpty model.newTaskDuration) then
                case String.toInt model.newTaskDuration of
                    Nothing ->
                        ( model, Cmd.none )

                    Just duration ->
                        render
                            ( { model
                                | tasks = model.tasks ++ [ model.newTaskName ]
                                , taskDurations = model.taskDurations ++ [ ( model.newTaskName, duration ) ]
                                , addingTask = False
                                , newTaskName = ""
                                , newTaskDuration = ""
                                , isLoading = False
                              }
                            , Cmd.none
                            )

            else
                ( model, Cmd.none )


render : ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
render ( model, cmd ) =
    ( model
    , Cmd.batch
        [ let
            -- Render task list
            taskList : List Layoutz.Element
            taskList =
                List.foldr
                    (\task ( rendered, idx ) ->
                        ( renderTask model idx task :: rendered
                        , idx - 1
                        )
                    )
                    ( [], List.length model.tasks - 1 )
                    model.tasks
                    |> Tuple.first

            -- Status section
            completedCount =
                Set.size model.completed

            totalCount =
                List.length model.tasks
          in
          (if model.addingTask then
            Layoutz.layout
                [ Layoutz.section "Task Manager" taskList
                , Layoutz.br
                , Layoutz.box "Add New Task"
                    [ Layoutz.text
                        ("Task name: "
                            ++ model.newTaskName
                            ++ (if String.isEmpty model.newTaskDuration then
                                    "_"

                                else
                                    ""
                               )
                        )
                    , Layoutz.text
                        ("Duration (steps): "
                            ++ model.newTaskDuration
                            ++ (if not (String.isEmpty model.newTaskDuration) then
                                    "_"

                                else
                                    ""
                               )
                        )
                    , Layoutz.br
                    , Layoutz.text "Type name (letters), then duration (digits)"
                    , Layoutz.text "Enter/Tab to add, ESC to cancel"
                    ]
                ]

           else if model.isLoading then
            let
                taskName =
                    model.tasks
                        |> List.drop model.loadingTaskIdx
                        |> List.head
                        |> Maybe.withDefault ""

                duration =
                    List.filter (\( n, _ ) -> n == taskName) model.taskDurations
                        |> List.head
                        |> Maybe.map Tuple.second
                        |> Maybe.withDefault 0

                progress =
                    toFloat model.loadProgress / toFloat duration
            in
            Layoutz.layout
                [ Layoutz.section "Task Manager" taskList
                , Layoutz.br
                , Layoutz.spinner "Processing..." model.spinFrame Layoutz.SpinnerDots
                , Layoutz.inlineBar taskName progress
                , Layoutz.text ("Progress: " ++ String.fromInt model.loadProgress ++ " / " ++ String.fromInt duration)
                ]

           else
            Layoutz.layout
                [ Layoutz.section "Task Manager" taskList
                , Layoutz.br
                , Layoutz.section "Status"
                    [ Layoutz.text ("Completed: " ++ String.fromInt completedCount ++ " / " ++ String.fromInt totalCount)
                    , Layoutz.br
                    , if completedCount == totalCount then
                        Layoutz.withColor Ansi.Color.Green <| Layoutz.text "🎉 All tasks completed!"

                      else
                        Layoutz.text "Select a task and press Enter to start"
                    ]
                , Layoutz.br
                , Layoutz.section "Controls"
                    [ Layoutz.ul
                        [ Layoutz.text "↑/↓ or W/S - Navigate"
                        , Layoutz.text "Enter - Start task"
                        , Layoutz.text "A - Add new task"
                        ]
                    ]
                ]
          )
            |> Layoutz.render
            |> (\rendered -> Ansi.Cursor.hide ++ Ansi.clearScreen ++ rendered)
            |> Ports.stdout
        , cmd
        ]
    )


renderTask : Model -> Int -> String -> Layoutz.Element
renderTask model idx task =
    let
        isSelected =
            idx == model.selected

        isCompleted =
            Set.member idx model.completed

        isCurrentlyLoading =
            model.isLoading && idx == model.loadingTaskIdx

        emoji =
            if isCompleted then
                "✅"

            else if isCurrentlyLoading then
                "⚡"

            else
                "📋"

        marker =
            if isSelected then
                "► "

            else
                "  "

        taskText =
            marker ++ emoji ++ " " ++ task
    in
    if isSelected then
        Layoutz.withColor Ansi.Color.Cyan <| Layoutz.text taskText

    else
        Layoutz.text taskText
