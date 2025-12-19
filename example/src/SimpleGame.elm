module SimpleGame exposing (..)

{-| Simple game demo - Collect gems, avoid devils!

Controls:

  - WASD or Arrow Keys to move
  - R to restart
  - ESC to quit

-}

import Ansi
import Ansi.Color
import Ansi.Cursor
import Ansi.Decode
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
    { tick : Float
    , playerX : Int
    , playerY : Int
    , items : List ( Int, Int )
    , score : Int
    , message : String
    , gameOver : Bool
    , level : Int
    , enemies : List Enemy
    , lives : Int
    , moveCount : Float -- Track moves to slow down enemies
    }


type alias Enemy =
    { x : Int
    , y : Int
    }


gameWidth =
    20


gameHeight =
    12



{- | Generate items for a level (deterministic pattern) -}


generateItems : Int -> List ( Int, Int )
generateItems level =
    let
        itemCount =
            3 + level

        -- Create a nice scattered pattern based on level
        positions =
            List.foldl
                (\i pos ->
                    let
                        x =
                            (i * 5 + level * 3) |> modBy gameWidth

                        y =
                            (i * 3 + level * 2) |> modBy gameHeight
                    in
                    ( x |> modBy gameWidth, y |> modBy gameHeight ) :: pos
                )
                []
                (List.range 0 (itemCount - 1))
    in
    List.take itemCount positions



{- | Generate enemies for a level (deterministic pattern) -}


generateEnemies : Int -> List Enemy
generateEnemies level =
    let
        enemyCount =
            1 + level
    in
    -- Place enemies in corners and edges, spread based on level
    List.foldl
        (\i pos ->
            { x = (i * 7 + level) |> modBy gameWidth
            , y = (i * 5 + level * 2) |> modBy gameHeight
            }
                :: pos
        )
        []
        (List.range 0 (enemyCount - 1))


init : () -> ( Model, Cmd Msg )
init () =
    render
        ( { tick = 0
          , playerX = gameWidth // 2
          , playerY = gameHeight // 2
          , items = generateItems 1
          , score = 0
          , message = "Collect all gems! Avoid the devils!"
          , gameOver = False
          , level = 1
          , enemies = generateEnemies 0
          , lives = 3
          , moveCount = 0
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

                    "w" ->
                        MoveUp

                    "W" ->
                        MoveUp

                    "s" ->
                        MoveDown

                    "S" ->
                        MoveDown

                    "a" ->
                        MoveLeft

                    "A" ->
                        MoveLeft

                    "d" ->
                        MoveRight

                    "D" ->
                        MoveRight

                    "r" ->
                        Restart

                    "R" ->
                        Restart

                    _ ->
                        if Ansi.Decode.isDownArrow input then
                            MoveDown

                        else if Ansi.Decode.isUpArrow input then
                            MoveUp

                        else if Ansi.Decode.isLeftArrow input then
                            MoveLeft

                        else if Ansi.Decode.isRightArrow input then
                            MoveRight

                        else
                            NoOp
            )
        ]


type Msg
    = Quit
    | NoOp
    | MoveUp
    | MoveDown
    | MoveLeft
    | MoveRight
    | Restart
    | Tick Float


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        Quit ->
            ( model, Ports.exit 0 )

        Restart ->
            init ()

        MoveUp ->
            if model.gameOver then
                ( model, Cmd.none )

            else
                let
                    newY =
                        max 0 (model.playerY - 1)
                in
                render ( processPlayerMove { model | playerY = newY }, Cmd.none )

        MoveDown ->
            if model.gameOver then
                ( model, Cmd.none )

            else
                let
                    newY =
                        min (gameHeight - 1) (model.playerY + 1)
                in
                render ( processPlayerMove { model | playerY = newY }, Cmd.none )

        MoveLeft ->
            if model.gameOver then
                ( model, Cmd.none )

            else
                let
                    newX =
                        max 0 (model.playerX - 1)
                in
                render ( processPlayerMove { model | playerX = newX }, Cmd.none )

        MoveRight ->
            if model.gameOver then
                ( model, Cmd.none )

            else
                let
                    newX =
                        min (gameWidth - 1) (model.playerX + 1)
                in
                render ( processPlayerMove { model | playerX = newX }, Cmd.none )

        Tick time ->
            if model.gameOver then
                ( model, Cmd.none )

            else if model.tick == 0 then
                ( { model
                    | tick = time / 1000
                  }
                , Cmd.none
                )

            else
                -- On tick, increment move count and potentially move enemies
                let
                    newMoveCount =
                        model.moveCount + (time / 1000 - model.tick)

                    newEnemies =
                        if newMoveCount >= 1 && (floor newMoveCount |> modBy 3000) == 0 then
                            List.map (moveEnemy model) model.enemies

                        else
                            model.enemies

                    -- Check if player hit by enemy
                    hitByEnemy =
                        newEnemies /= [] && List.any (\e -> e.x == model.playerX && e.y == model.playerY) newEnemies
                in
                render
                    ( if hitByEnemy && model.lives > 1 then
                        { model
                            | lives = model.lives - 1
                            , enemies = newEnemies
                            , message = "Ouch! Lives left: " ++ String.fromInt (model.lives - 1)
                            , moveCount = newMoveCount
                        }

                      else if hitByEnemy then
                        { model
                            | gameOver = True
                            , message = "💀 Game Over! Press R to restart"
                            , moveCount = newMoveCount
                        }

                      else
                        { model
                            | enemies = newEnemies
                            , moveCount = newMoveCount
                        }
                    , Cmd.none
                    )


{-| Move an enemy towards the player (simple chase AI)
-}
moveEnemy : Model -> Enemy -> Enemy
moveEnemy model enemy =
    let
        dx =
            if model.playerX > enemy.x then
                1

            else if model.playerX < enemy.x then
                -1

            else
                0

        dy =
            if model.playerY > enemy.y then
                1

            else if model.playerY < enemy.y then
                -1

            else
                0

        newX =
            max 0 (min (gameWidth - 1) (enemy.x + dx))

        newY =
            max 0 (min (gameHeight - 1) (enemy.y + dy))
    in
    { x = newX, y = newY }


{-| Check if player collected an item and update state
-}
processPlayerMove : Model -> Model
processPlayerMove model =
    let
        playerPos =
            ( model.playerX, model.playerY )

        newMoveCount =
            model.moveCount + 1

        -- Check for item collection
        collectedItem =
            List.any (\item -> item == playerPos) model.items

        newItems =
            List.filter ((/=) playerPos) model.items

        newScore =
            if collectedItem then
                model.score + 10

            else
                model.score

        -- Move enemies towards player only every 3rd move
        newEnemies =
            if (floor newMoveCount |> modBy 3) == 0 then
                List.map (moveEnemy model) model.enemies

            else
                model.enemies

        -- Check if player hit by enemy
        hitByEnemy =
            List.any (\e -> e.x == model.playerX && e.y == model.playerY) newEnemies

        -- Handle level completion
        levelComplete =
            collectedItem && List.isEmpty newItems
    in
    if levelComplete then
        let
            newLevel =
                model.level + 1
        in
        { model
            | items = generateItems newLevel
            , score = newScore
            , level = newLevel
            , enemies = generateEnemies newLevel
            , message = "Level " ++ String.fromInt newLevel ++ "! More enemies!"
            , moveCount = newMoveCount
        }

    else if hitByEnemy then
        let
            newLives =
                model.lives - 1
        in
        if newLives <= 0 then
            { model
                | lives = 0
                , gameOver = True
                , enemies = newEnemies
                , message = "💀 Game Over! Press R to restart"
                , moveCount = newMoveCount
            }

        else
            { model
                | lives = newLives
                , enemies = newEnemies
                , message = "💥 Hit! Lives left: " ++ String.fromInt newLives
                , moveCount = newMoveCount
            }

    else if collectedItem then
        { model
            | items = newItems
            , score = newScore
            , enemies = newEnemies
            , message = "Score: " ++ String.fromInt newScore ++ " | Gems left: " ++ String.fromInt (List.length newItems)
            , moveCount = newMoveCount
        }

    else
        { model
            | enemies = newEnemies
            , message = "Score: " ++ String.fromInt model.score ++ " | Lives: " ++ String.fromInt model.lives ++ " | Level: " ++ String.fromInt model.level
            , moveCount = newMoveCount
        }


render : ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
render ( model, cmd ) =
    ( model
    , Cmd.batch
        [ let
            -- Render game board
            renderCell x y =
                if x == model.playerX && y == model.playerY then
                    "🧙"

                else if List.any (\e -> e.x == x && e.y == y) model.enemies then
                    "👹"

                else if List.any ((==) ( x, y )) model.items then
                    "💎"

                else
                    "⬜"

            renderRow y =
                List.map (\x -> renderCell x y)
                    (List.range 0 (gameWidth - 1))
                    |> String.concat
                    |> Layoutz.text

            gameBoard =
                List.map renderRow
                    (List.range 0 (gameHeight - 1))
                    |> Layoutz.layout

            -- Stats section
            hearts =
                String.repeat model.lives "💖"

            stats =
                Layoutz.layout
                    [ Layoutz.text <| "Score: " ++ String.fromInt model.score
                    , Layoutz.text <| "Lives: " ++ hearts
                    , Layoutz.text <| "Level: " ++ String.fromInt model.level
                    , Layoutz.text <| "Gems left: " ++ String.fromInt (List.length model.items)
                    ]

            -- Game over section
            gameOverSection =
                if model.gameOver then
                    Layoutz.section "💀 Game Over"
                        [ Layoutz.text <| "Final Score: " ++ String.fromInt model.score
                        , Layoutz.text <| "Reached Level: " ++ String.fromInt model.level
                        , Layoutz.text "Press R to restart!"
                        ]

                else
                    Layoutz.text ""

            controls =
                Layoutz.section "Controls"
                    [ Layoutz.ul
                        [ Layoutz.text "🧙 You | 👹 Devil | 💎 Gems"
                        , Layoutz.text "WASD or Arrow Keys - Move"
                        , Layoutz.text "R - Restart | ESC - Quit"
                        , Layoutz.text "Devils move automatically!"
                        ]
                    ]
          in
          Layoutz.layout
            [ gameBoard
            , Layoutz.br
            , Layoutz.row [ Layoutz.section "Stats" [ stats ], Layoutz.section "Status" [ Layoutz.text model.message ] ]
            , gameOverSection
            , Layoutz.br
            , controls
            ]
            |> Layoutz.render
            |> (\rendered -> Ansi.Cursor.hide ++ Ansi.clearScreen ++ rendered)
            |> Ports.stdout
        , cmd
        ]
    )
