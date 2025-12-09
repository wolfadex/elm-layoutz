module Layoutz exposing
    ( Element
    , ol, ul
    , layout, section
    , text, br
    , render
    )

{-|

@docs Element
@docs ol, ul
@docs layout, section
@docs text, br
@docs render

-}

import Ansi
import Ansi.Color
import Ansi.Cursor
import Ansi.String


type Element
    = Text String
    | UnorderedList (List Element)
    | OL (List Element)
    | AutoCenter Element
    | Centered String Int
    | Colored Ansi.Color.Color Element
    | Styled Style Element
    | Box String (List Element) Border
    | StatusCard String String Border
    | Table (List String) (List (List Element)) Border
    | LineBreak
    | Section { title : String, content : List Element, glyph : String, flankingChars : Int }
    | Layout (List Element)


type Border
    = BorderNormal
    | BorderDouble
    | BorderThick
    | BorderRound
    | BorderNone


type Style
    = StyleNoStyle
    | StyleBold
    | StyleDim
    | StyleItalic
    | StyleUnderline
    | StyleBlink
    | StyleReverse
    | StyleHidden
    | StyleStrikethrough
    | StyleCombined (List Style)


text : String -> Element
text =
    Text


layout : List Element -> Element
layout =
    Layout


section : String -> List Element -> Element
section title content =
    Section
        { title = title
        , content = content
        , glyph = "="
        , flankingChars = 3
        }


br : Element
br =
    LineBreak


ul : List Element -> Element
ul =
    UnorderedList


ol : List Element -> Element
ol =
    OL


render : Element -> String
render element =
    Ansi.Cursor.hide
        ++ Ansi.clearScreen
        ++ renderElement element


renderElement : Element -> String
renderElement element =
    case element of
        Text txt ->
            txt

        UnorderedList items ->
            let
                renderAtLevel level itemList =
                    let
                        currentBullet =
                            case modBy 3 level of
                                0 ->
                                    "•"

                                1 ->
                                    "◦"

                                2 ->
                                    "▪"

                                _ ->
                                    "•"

                        indent =
                            String.repeat (level * 2) " "
                    in
                    String.join "\n" <| List.map (renderItem level indent currentBullet) itemList

                renderItem level indent bullet item =
                    case item of
                        UnorderedList nested ->
                            renderAtLevel (level + 1) nested

                        _ ->
                            let
                                content =
                                    renderElement item

                                contentLines =
                                    String.lines content
                            in
                            case contentLines of
                                [] ->
                                    indent ++ bullet ++ " "

                                [ singleLine ] ->
                                    indent ++ bullet ++ " " ++ singleLine

                                firstLine :: restLines ->
                                    let
                                        firstOutput =
                                            indent ++ bullet ++ " " ++ firstLine

                                        restIndent =
                                            String.repeat (String.length indent + String.length bullet + 1) " "

                                        restOutput =
                                            List.map (\r -> restIndent ++ r) restLines
                                    in
                                    String.join "\n" (firstOutput :: restOutput)
            in
            renderAtLevel 0 items

        OL children ->
            Debug.todo ""

        AutoCenter child ->
            Debug.todo ""

        Centered content contextWidth ->
            Debug.todo ""

        Colored color child ->
            Debug.todo ""

        Styled style child ->
            Debug.todo ""

        Box title children border ->
            Debug.todo ""

        StatusCard label content border ->
            Debug.todo ""

        Table labels children border ->
            Debug.todo ""

        LineBreak ->
            "\n"

        Section { title, content, glyph, flankingChars } ->
            let
                header =
                    String.repeat flankingChars glyph ++ " " ++ title ++ " " ++ String.repeat flankingChars glyph

                body =
                    renderElement (Layout content)
            in
            header ++ "\n" ++ body

        Layout elems ->
            let
                -- Calculate max width of all non-AutoCenter elements
                nonAutoCenterElements =
                    List.filter (isAutoCenter >> not) elems

                maxWidth =
                    if List.isEmpty nonAutoCenterElements then
                        -- fallback
                        80

                    else
                        nonAutoCenterElements
                            |> List.map width
                            |> List.maximum
                            |> Maybe.withDefault 0

                -- Render elements, providing context width to AutoCenter elements
                renderedElements =
                    List.map (renderWithContext maxWidth) elems

                isAutoCenter el =
                    case el of
                        AutoCenter _ ->
                            True

                        _ ->
                            False

                renderWithContext contextWidth elem =
                    case elem of
                        AutoCenter el ->
                            renderElement (Centered (renderElement el) contextWidth)

                        _ ->
                            renderElement elem
            in
            String.join "\n" renderedElements



-- INTERNAL


width : Element -> Int
width element =
    let
        rendered =
            renderElement element

        renderedLines =
            String.lines rendered
    in
    if List.isEmpty renderedLines then
        0

    else
        renderedLines
            |> List.map visibleLength
            |> List.maximum
            |> Maybe.withDefault 0



-- | Calculate visible width of string (handles ANSI codes, emoji, CJK)


visibleLength : String -> Int
visibleLength =
    Ansi.String.width



-- Calculate element height (number of lines)


height : Element -> Int
height element =
    let
        rendered =
            renderElement element
    in
    if String.isEmpty rendered then
        1

    else
        List.length (String.lines rendered)
