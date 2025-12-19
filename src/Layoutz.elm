module Layoutz exposing
    ( Element
    , text, br
    , ol, ul
    , layout, section
    , table, keyValue
    , Tree, tree, leaf, branch
    , inlineBar
    , box
    , statusCard
    , margin
    , row, tightRow
    , Border(..), withBorder
    , Style(..), withStyle
    , withColor, withBackgroundColor
    , wrap
    , center, centerInWidth
    , underline, underlineWith, underlineColored
    , render
    )

{-|

@docs Element
@docs text, br
@docs ol, ul
@docs layout, section
@docs table, keyValue
@docs Tree, tree, leaf, branch
@docs inlineBar
@docs box
@docs statusCard
@docs margin
@docs row, tightRow

@docs Border, withBorder
@docs Style, withStyle
@docs withColor, withBackgroundColor
@docs wrap
@docs center, centerInWidth
@docs underline, underlineWith, underlineColored

@docs render

-}

import Ansi.Box
import Ansi.Color
import Ansi.Font
import Ansi.String


type Element
    = Text String
    | UnorderedList (List Element)
    | OrderedList (List Element)
    | AutoCenter Element
    | Centered String Int
    | Colored Ansi.Color.Color Element
    | ColoredBackground Ansi.Color.Color Element
    | Styled Style Element
    | Box String (List Element) Border
    | StatusCard String String Border
    | Table (List String) (List (List Element)) Border
    | LineBreak
    | Section { title : String, content : List Element, glyph : String, flankingChars : Int }
    | Layout (List Element)
    | TreeElement Tree
    | InlineBar String Float
    | Margin String (List Element)
    | Row (List Element) Bool
    | KeyValue (List ( String, String ))
    | Underlined String String (Maybe Ansi.Color.Color)


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
    OrderedList


table : List String -> List (List Element) -> Element
table headers rows =
    Table headers rows BorderNormal


type Tree
    = Tree String (List Tree)


tree : String -> List Tree -> Element
tree name children =
    TreeElement (Tree name children)


leaf : String -> Tree
leaf name =
    Tree name []


branch : String -> List Tree -> Tree
branch name children =
    Tree name children


inlineBar : String -> Float -> Element
inlineBar =
    InlineBar


box : String -> List Element -> Element
box title elements =
    Box title elements BorderNormal


margin : String -> List Element -> Element
margin prefix elements =
    Margin prefix elements



-- hr : Element
-- hr =  (HorizontalRule "─" 50)


row : List Element -> Element
row elements =
    Row elements False


{-| Create horizontal row with no spacing between elements (for gradients, etc.)
-}
tightRow : List Element -> Element
tightRow elements =
    Row elements True


keyValue : List ( String, String ) -> Element
keyValue pairs =
    KeyValue pairs


statusCard : String -> String -> Element
statusCard label content =
    StatusCard label content BorderNormal



--


withBorder : Border -> Element -> Element
withBorder border element =
    case element of
        Box title elements _ ->
            Box title elements border

        StatusCard label content _ ->
            StatusCard label content border

        Table headers rows _ ->
            Table headers rows border

        Colored color elem ->
            Colored color (withBorder border elem)

        ColoredBackground color elem ->
            ColoredBackground color (withBorder border elem)

        Styled style elem ->
            Styled style (withBorder border elem)

        _ ->
            element


withColor : Ansi.Color.Color -> Element -> Element
withColor =
    Colored


withBackgroundColor : Ansi.Color.Color -> Element -> Element
withBackgroundColor =
    ColoredBackground


withStyle : Style -> Element -> Element
withStyle =
    Styled


wrap : Int -> String -> Element
wrap targetWidth content =
    let
        ws =
            String.words content

        wrappedLines =
            wrapWords targetWidth ws

        wrapWords : Int -> List String -> List String
        wrapWords maxWidth wordsList =
            case wordsList of
                [] ->
                    []

                _ ->
                    let
                        ( line, rest ) =
                            takeLine maxWidth wordsList
                    in
                    line :: wrapWords maxWidth rest

        takeLine : Int -> List String -> ( String, List String )
        takeLine maxWidth words =
            case words of
                [] ->
                    ( "", [] )

                firstWord :: restWords ->
                    let
                        go currentLen acc wds =
                            case wds of
                                [] ->
                                    ( String.join " " (List.reverse acc), [] )

                                nextWord :: remainingWords ->
                                    if currentLen + 1 + visibleLength nextWord <= maxWidth then
                                        go (currentLen + 1 + visibleLength nextWord) (nextWord :: acc) remainingWords

                                    else
                                        ( String.join " " (List.reverse acc), nextWord :: remainingWords )
                    in
                    if visibleLength firstWord > maxWidth then
                        ( firstWord, restWords )
                        -- Word too long, put it on its own line

                    else
                        go (visibleLength firstWord) [ firstWord ] restWords
    in
    layout (List.map text wrappedLines)


underline : Element -> Element
underline element =
    Underlined (render element) "─" Nothing


{-| Add underline with custom character
-}
underlineWith : String -> Element -> Element
underlineWith char element =
    Underlined (render element) char Nothing


{-| Add colored underline with custom character and color
Example usage:
Layoutz.underlineColored "=" Ansi.Color.Red <| Layoutz.text "Error Section"
Layoutz.underlineColored "~" Ansi.Color.Green <| Layoutz.text "Success"
Layoutz.underlineColored "─" Ansi.Color.BrightCyan <| Layoutz.text "Info"
-}
underlineColored : String -> Ansi.Color.Color -> Element -> Element
underlineColored char color element =
    Underlined (render element) char (Just color)


center : Element -> Element
center element =
    AutoCenter element


{-| Center element within specified width
-}
centerInWidth : Int -> Element -> Element
centerInWidth targetWidth element =
    Centered (render element) targetWidth



--


render : Element -> String
render element =
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
                    itemList
                        |> List.map (renderItem level indent currentBullet)
                        |> String.join "\n"

                renderItem level indent bullet item =
                    case item of
                        UnorderedList nested ->
                            renderAtLevel (level + 1) nested

                        _ ->
                            let
                                content =
                                    render item

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
                                            String.repeat (visibleLength indent + visibleLength bullet + 1) " "

                                        restOutput =
                                            List.map (\r -> restIndent ++ r) restLines
                                    in
                                    String.join "\n" (firstOutput :: restOutput)
            in
            renderAtLevel 0 items

        OrderedList items ->
            let
                renderAtLevel level itemList =
                    let
                        indent =
                            String.repeat (level * 2) " "
                    in
                    String.join "\n" <| List.indexedMap (renderItem level indent) itemList

                renderItem level indent num item =
                    case item of
                        OrderedList nested ->
                            renderAtLevel (level + 1) nested

                        _ ->
                            let
                                numStr =
                                    formatNumber level (num + 1) ++ ". "

                                content =
                                    render item

                                contentLines =
                                    String.lines content
                            in
                            case contentLines of
                                [] ->
                                    indent ++ numStr

                                [ singleLine ] ->
                                    indent ++ numStr ++ singleLine

                                firstLine :: restLines ->
                                    let
                                        firstOutput =
                                            indent ++ numStr ++ firstLine

                                        restIndent =
                                            String.repeat (visibleLength numStr) " "

                                        restOutput =
                                            List.map (\r -> (indent ++ restIndent) ++ r) restLines
                                    in
                                    String.join "\n" (firstOutput :: restOutput)

                formatNumber : Int -> Int -> String
                formatNumber lvl num =
                    case modBy 3 lvl of
                        0 ->
                            -- 1, 2, 3
                            String.fromInt num

                        1 ->
                            -- a, b, c
                            String.fromChar (Char.fromCode (96 + num))

                        _ ->
                            -- i, ii, iii
                            toRoman num

                toRoman : Int -> String
                toRoman i =
                    case i of
                        1 ->
                            "i"

                        2 ->
                            "ii"

                        3 ->
                            "iii"

                        4 ->
                            "iv"

                        5 ->
                            "v"

                        6 ->
                            "vi"

                        7 ->
                            "vii"

                        8 ->
                            "viii"

                        9 ->
                            "ix"

                        10 ->
                            "x"

                        n ->
                            String.fromInt n
            in
            renderAtLevel 0 items

        AutoCenter el ->
            render el

        Centered content targetWidth ->
            String.join "\n" <| List.map (centerString targetWidth) (String.lines content)

        Colored color el ->
            mapLines (Ansi.Color.fontColor color) (render el)

        ColoredBackground color el ->
            mapLines (Ansi.Color.backgroundColor color) (render el)

        Styled style el ->
            mapLines (wrapStyle style) (render el)

        Box title elements border ->
            let
                elementStrings =
                    List.map render elements

                content =
                    String.join "\n" elementStrings

                contentLines =
                    if String.isEmpty content then
                        [ "" ]

                    else
                        String.lines content

                contentWidth =
                    contentLines
                        |> List.map visibleLength
                        |> List.maximum
                        |> Maybe.withDefault 0

                titleWidth =
                    if String.isEmpty title then
                        0

                    else
                        visibleLength title + 2

                innerWidth =
                    max contentWidth titleWidth

                totalWidth =
                    innerWidth + 4

                { topLeft, topRight, bottomLeft, bottomRight, top, left } =
                    borderChars border

                hChar =
                    top

                topBorder =
                    if String.isEmpty title then
                        topLeft ++ String.repeat (totalWidth - 2) hChar ++ topRight

                    else
                        let
                            titlePadding =
                                totalWidth - visibleLength title - 2

                            leftPad =
                                titlePadding // 2

                            rightPad =
                                titlePadding - leftPad
                        in
                        topLeft ++ String.repeat leftPad hChar ++ title ++ String.repeat rightPad hChar ++ topRight

                bottomBorder =
                    bottomLeft ++ String.repeat (totalWidth - 2) hChar ++ bottomRight

                paddedContent =
                    List.map (\line -> left ++ " " ++ padRight innerWidth line ++ " " ++ left) contentLines
            in
            String.join "\n" (topBorder :: paddedContent ++ [ bottomBorder ])

        StatusCard label content border ->
            let
                labelLines =
                    String.lines label

                contentLines =
                    String.lines content

                allLines =
                    labelLines ++ contentLines

                maxWidth =
                    allLines
                        |> List.map visibleLength
                        |> List.maximum
                        |> Maybe.withDefault 0

                contentWidth =
                    maxWidth + 2

                { topLeft, topRight, bottomLeft, bottomRight, top, left } =
                    borderChars border

                hChar =
                    top

                topBorder =
                    topLeft ++ String.repeat (contentWidth + 2) hChar ++ topRight

                bottomBorder =
                    bottomLeft ++ String.repeat (contentWidth + 2) hChar ++ bottomRight

                createCardLine line =
                    left ++ " " ++ padRight contentWidth line ++ " " ++ left
            in
            (topBorder :: List.map createCardLine allLines ++ [ bottomBorder ])
                |> String.join "\n"

        Table headers rows border ->
            let
                normalizeRow : Int -> List Element -> List Element
                normalizeRow expectedLen rowData =
                    let
                        currentLen =
                            List.length rowData
                    in
                    if currentLen >= expectedLen then
                        List.take expectedLen rowData

                    else
                        rowData ++ List.repeat (expectedLen - currentLen) (text "")

                calculateColumnWidths : List String -> List (List Element) -> List Int
                calculateColumnWidths hdrs rws =
                    let
                        headerWidths =
                            List.map visibleLength hdrs

                        rowWidths =
                            List.map
                                (List.map
                                    (render
                                        >> String.lines
                                        >> List.map
                                            (\line ->
                                                visibleLength (Debug.log "line" line)
                                                    |> Debug.log "lineLen"
                                            )
                                        >> List.maximum
                                        >> Maybe.withDefault 0
                                    )
                                )
                                rws

                        allWidths =
                            headerWidths :: rowWidths
                    in
                    List.map (List.maximum >> Maybe.withDefault 0) (transpose allWidths)

                renderTableRow : List Int -> String -> List Element -> List String
                renderTableRow widths vChars rowData =
                    let
                        cellContents =
                            List.map render rowData
                                |> Debug.log "cellContents"

                        cellLines =
                            List.map String.lines cellContents
                                |> Debug.log "cellLines"

                        maxCellHeight =
                            cellLines
                                |> List.map List.length
                                |> List.maximum
                                |> Maybe.withDefault 1
                                |> Debug.log "maxCellHeight"

                        paddedCells =
                            List.map2 (padCell maxCellHeight) widths cellLines
                                |> Debug.log "paddedCells"

                        tableRows =
                            transpose paddedCells
                                |> Debug.log "tableRows"
                    in
                    List.map
                        (\rowCells ->
                            vChars ++ " " ++ String.join (" " ++ vChars ++ " ") rowCells ++ " " ++ vChars
                        )
                        tableRows

                padCell : Int -> Int -> List String -> List String
                padCell cellHeight cellWidth cellLines =
                    let
                        paddedLines =
                            cellLines ++ List.repeat (cellHeight - List.length cellLines) ""
                    in
                    List.map (padRight cellWidth) paddedLines

                normalizedRows =
                    rows
                        |> List.map (normalizeRow (List.length headers))

                columnWidths =
                    calculateColumnWidths headers normalizedRows
                        |> Debug.log "colWidths"

                { topLeft, topRight, bottomLeft, bottomRight, top, left, leftSplit, rightSplit, split } =
                    borderChars border

                hChar =
                    top

                -- Fixed border construction with proper connectors
                topConnector =
                    case border of
                        BorderRound ->
                            "┬"

                        BorderNormal ->
                            "┬"

                        BorderDouble ->
                            "╦"

                        BorderThick ->
                            "┳"

                        BorderNone ->
                            " "

                topParts =
                    List.map (\w -> String.repeat w hChar) columnWidths

                topBorder =
                    topLeft ++ hChar ++ String.concat (List.intersperse (hChar ++ topConnector ++ hChar) topParts) ++ hChar ++ topRight

                -- Create proper separator with tee connectors
                separatorParts =
                    List.map (\w -> String.repeat w hChar) columnWidths
                        |> Debug.log "sepParts"

                separatorBorder =
                    leftSplit ++ hChar ++ String.concat (List.intersperse (hChar ++ split ++ hChar) separatorParts) ++ hChar ++ rightSplit

                -- Create proper bottom border with bottom connectors
                bottomConnector =
                    case border of
                        BorderRound ->
                            "┴"

                        -- Special case for round borders
                        BorderNormal ->
                            "┴"

                        BorderDouble ->
                            "╩"

                        BorderThick ->
                            "┻"

                        BorderNone ->
                            " "

                bottomParts =
                    List.map (\w -> String.repeat w hChar) columnWidths

                bottomBorder =
                    bottomLeft ++ hChar ++ String.concat (List.intersperse (hChar ++ bottomConnector ++ hChar) bottomParts) ++ hChar ++ bottomRight

                -- Create header row
                headerCells =
                    List.map2 padRight columnWidths headers

                headerRow =
                    left ++ " " ++ String.join (" " ++ left ++ " ") headerCells ++ " " ++ left

                -- Create data rows
                dataRows =
                    normalizedRows
                        |> Debug.log "normRows"
                        |> List.concatMap (renderTableRow columnWidths left)
                        |> Debug.log "dataRows"
            in
            String.join "\n" ([ topBorder, headerRow, separatorBorder ] ++ dataRows ++ [ bottomBorder ])

        LineBreak ->
            "\n"

        Section { title, content, glyph, flankingChars } ->
            let
                header =
                    String.repeat flankingChars glyph ++ " " ++ title ++ " " ++ String.repeat flankingChars glyph

                body =
                    render (Layout content)
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
                            render (Centered (render el) contextWidth)

                        _ ->
                            render elem
            in
            String.join "\n" renderedElements

        TreeElement treeData ->
            let
                renderTree (Tree name children) prefix isLast parentPrefixes =
                    let
                        nodeLine =
                            if List.isEmpty parentPrefixes then
                                name

                            else
                                prefix
                                    ++ (if isLast then
                                            "└── "

                                        else
                                            "├── "
                                       )
                                    ++ name

                        childPrefix =
                            if List.isEmpty parentPrefixes then
                                ""

                            else
                                prefix
                                    ++ (if isLast then
                                            "    "

                                        else
                                            "│   "
                                       )

                        childLines : List String
                        childLines =
                            let
                                lastIdx =
                                    List.length children - 1
                            in
                            List.foldl
                                (\child ( res, idx ) ->
                                    ( renderTree child childPrefix (idx == lastIdx) (parentPrefixes ++ [ not isLast ]) :: res
                                    , idx + 1
                                    )
                                )
                                ( [], 0 )
                                children
                                |> Tuple.first
                                |> List.reverse
                    in
                    if List.isEmpty children then
                        nodeLine

                    else
                        nodeLine ++ "\n" ++ String.join "\n" childLines
            in
            renderTree treeData "" True []

        InlineBar label progress ->
            let
                clampedProgress =
                    max 0.0 (min 1.0 progress)

                barWidth =
                    20

                filledSegments =
                    floor (clampedProgress * barWidth)

                emptySegments =
                    barWidth - filledSegments

                bar =
                    String.repeat filledSegments "█" ++ String.repeat emptySegments "─"

                percentage =
                    floor (clampedProgress * 100)
            in
            label ++ " [" ++ bar ++ "] " ++ String.fromInt percentage ++ "%"

        Margin prefix elems ->
            let
                content =
                    case elems of
                        [ single ] ->
                            render single

                        _ ->
                            render (Layout elems)
            in
            content
                |> String.lines
                |> List.map (\line -> (prefix ++ " ") ++ line)
                |> String.join "\n"

        Row elems tight ->
            case elems of
                [] ->
                    ""

                _ ->
                    let
                        separator =
                            if tight then
                                ""

                            else
                                " "

                        elementStrings =
                            List.map render elems

                        elementLines =
                            List.map String.lines elementStrings

                        maxHeight =
                            List.map List.length elementLines
                                |> List.maximum
                                |> Maybe.withDefault 0

                        elementWidths =
                            List.map
                                (Maybe.withDefault 0 << List.maximum << List.map visibleLength)
                                elementLines

                        paddedElements =
                            List.map2 padElement elementWidths elementLines

                        padElement : Int -> List String -> List String
                        padElement cellWidth linesList =
                            let
                                currentLines =
                                    linesList ++ List.repeat (maxHeight - List.length linesList) ""
                            in
                            List.map (padRight cellWidth) currentLines
                    in
                    transpose paddedElements
                        |> List.map (String.join separator)
                        |> String.join "\n"

        KeyValue pairs ->
            if List.isEmpty pairs then
                ""

            else
                let
                    maxKeyLength =
                        pairs
                            |> List.map (Tuple.first >> visibleLength)
                            |> List.maximum
                            |> Maybe.withDefault 0

                    alignmentPosition =
                        maxKeyLength + 2

                    renderPair alignPos ( key, value ) =
                        let
                            keyWithColon =
                                key ++ ":"

                            spacesNeeded =
                                alignPos - visibleLength keyWithColon

                            padding =
                                String.repeat (max 1 spacesNeeded) " "
                        in
                        keyWithColon ++ padding ++ value
                in
                pairs
                    |> List.map (renderPair alignmentPosition)
                    |> String.join "\n"

        Underlined content underlineChar maybeColor ->
            let
                contentLines =
                    String.lines content

                maxWidth =
                    if List.isEmpty contentLines then
                        0

                    else
                        contentLines
                            |> List.map visibleLength
                            |> List.maximum
                            |> Maybe.withDefault 0

                repeats =
                    maxWidth // String.length underlineChar

                remainder =
                    maxWidth |> modBy (String.length underlineChar)

                underlinePart =
                    String.repeat repeats underlineChar ++ String.left remainder underlineChar

                coloredUnderline =
                    maybeColor
                        |> Maybe.map (\color -> Ansi.Color.fontColor color underlinePart)
                        |> Maybe.withDefault underlinePart
            in
            content ++ "\n" ++ coloredUnderline



-- INTERNAL


{-| Helper: pad a string to a target width on the right (ANSI-aware)
-}
padRight : Int -> String -> String
padRight targetWidth str =
    str ++ String.repeat (max 0 (targetWidth - visibleLength str)) " "


{-| Helper: pad a string to a target width on the left (ANSI-aware)
-}
padLeft : Int -> String -> String
padLeft targetWidth str =
    String.repeat (max 0 (targetWidth - visibleLength str)) " " ++ str


borderChars :
    Border
    ->
        { topLeft : String
        , topRight : String
        , bottomLeft : String
        , bottomRight : String
        , bottom : String
        , top : String
        , right : String
        , left : String
        , leftSplit : String
        , rightSplit : String
        , split : String
        }
borderChars border =
    case border of
        BorderNormal ->
            { topLeft = "┌"
            , topRight = "┐"
            , bottomLeft = "└"
            , bottomRight = "┘"
            , bottom = "─"
            , top = "─"
            , right = "│"
            , left = "│"
            , leftSplit = "├"
            , rightSplit = "┤"
            , split = "┼"
            }

        BorderDouble ->
            { topLeft = "╔"
            , topRight = "╗"
            , bottomLeft = "╚"
            , bottomRight = "╝"
            , bottom = "═"
            , top = "═"
            , right = "║"
            , left = "║"
            , leftSplit = "╠"
            , rightSplit = "╣"
            , split = "╬"
            }

        BorderThick ->
            { topLeft = "┏"
            , topRight = "┓"
            , bottomLeft = "┗"
            , bottomRight = "┛"
            , bottom = "━"
            , top = "━"
            , right = "┃"
            , left = "┃"
            , leftSplit = "┣"
            , rightSplit = "┫"
            , split = "╋"
            }

        BorderRound ->
            { topLeft = "╭"
            , topRight = "╮"
            , bottomLeft = "╰"
            , bottomRight = "╯"
            , bottom = "─"
            , top = "─"
            , right = "│"
            , left = "│"
            , leftSplit = "├"
            , rightSplit = "┤"
            , split = "┼"
            }

        BorderNone ->
            { topLeft = " "
            , topRight = " "
            , bottomLeft = " "
            , bottomRight = " "
            , bottom = " "
            , top = " "
            , right = " "
            , left = " "
            , leftSplit = " "
            , rightSplit = " "
            , split = " "
            }


wrapStyle : Style -> String -> String
wrapStyle style str =
    case style of
        StyleNoStyle ->
            str

        StyleBold ->
            Ansi.Font.bold str

        StyleDim ->
            Ansi.Font.faint str

        StyleItalic ->
            Ansi.Font.italic str

        StyleUnderline ->
            Ansi.Font.underline str

        StyleBlink ->
            Ansi.Font.blink str

        StyleHidden ->
            Ansi.Font.hide ++ str ++ Ansi.Font.show

        StyleStrikethrough ->
            Ansi.Font.strikeThrough str

        StyleCombined styles ->
            List.foldl wrapStyle str styles


mapLines : (String -> String) -> String -> String
mapLines f str =
    let
        ls =
            String.lines str

        hasTrailingNewline =
            String.endsWith "\n" str
    in
    if hasTrailingNewline then
        String.join "\n" (List.map f ls) ++ "\n"

    else
        String.join "\n" (List.map f ls)


centerString : Int -> String -> String
centerString targetWidth str =
    let
        len =
            visibleLength str

        totalPadding =
            targetWidth - len

        leftPad =
            String.repeat (totalPadding // 2) " "

        rightPad =
            String.repeat (totalPadding - visibleLength leftPad) " "
    in
    if len >= targetWidth then
        str

    else
        leftPad ++ str ++ rightPad


width : Element -> Int
width element =
    let
        rendered =
            render element

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
            render element
    in
    if String.isEmpty rendered then
        1

    else
        List.length (String.lines rendered)


transpose : List (List a) -> List (List a)
transpose listOfLists =
    List.foldr (List.map2 (::)) (List.repeat (rowsLength listOfLists) []) listOfLists


rowsLength : List (List a) -> Int
rowsLength listOfLists =
    case listOfLists of
        [] ->
            0

        x :: _ ->
            List.length x
