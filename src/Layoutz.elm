module Layoutz exposing
    ( render
    , Element
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
    , SpinnerStyle(..), spinner
    , Border(..), withBorder
    , Style(..), withStyle
    , withColor, withBackgroundColor
    , wrap
    , center, centerInWidth
    , underline, underlineWith, underlineColored
    )

{-|

@docs render


# Elements

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
@docs SpinnerStyle, spinner


# Styling

@docs Border, withBorder
@docs Style, withStyle
@docs withColor, withBackgroundColor
@docs wrap
@docs center, centerInWidth
@docs underline, underlineWith, underlineColored

-}

import Ansi.Color
import Ansi.Font
import Ansi.String


{-| -}
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
    | Spinner String Int SpinnerStyle


{-| -}
type Border
    = BorderNormal
    | BorderDouble
    | BorderThick
    | BorderRound
    | BorderNone


{-| -}
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


{-| -}
text : String -> Element
text =
    Text


{-| -}
layout : List Element -> Element
layout =
    Layout


{-| -}
section : String -> List Element -> Element
section title content =
    Section
        { title = title
        , content = content
        , glyph = "="
        , flankingChars = 3
        }


{-| -}
br : Element
br =
    LineBreak


hr : Element
hr =
    -- (HorizontalRule "─" 50)
    Debug.odo ""


vr : Element
vr =
    -- (HorizontalRule "─" 50)
    Debug.odo ""


{-| -}
ul : List Element -> Element
ul =
    UnorderedList


{-| -}
ol : List Element -> Element
ol =
    OrderedList


{-| -}
table : List String -> List (List Element) -> Element
table headers rows =
    Table headers rows BorderNormal


{-| -}
type Tree
    = Tree String (List Tree)


{-| -}
tree : String -> List Tree -> Element
tree name children =
    TreeElement (Tree name children)


{-| -}
leaf : String -> Tree
leaf name =
    Tree name []


{-| -}
branch : String -> List Tree -> Tree
branch name children =
    Tree name children


chart : List ( String, Int ) -> Element
chart =
    Debug.todo ""


{-| -}
inlineBar : String -> Float -> Element
inlineBar =
    InlineBar


{-| -}
box : String -> List Element -> Element
box title elements =
    Box title elements BorderNormal


{-| -}
margin : String -> List Element -> Element
margin prefix elements =
    Margin prefix elements


pad : Int -> Element -> Element
pad =
    Debug.todo ""


{-| -}
row : List Element -> Element
row elements =
    Row elements False


{-| Create horizontal row with no spacing between elements (for gradients, etc.)
-}
tightRow : List Element -> Element
tightRow elements =
    Row elements True


{-| -}
keyValue : List ( String, String ) -> Element
keyValue pairs =
    KeyValue pairs


{-| -}
statusCard : String -> String -> Element
statusCard label content =
    StatusCard label content BorderNormal



--


{-| -}
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


{-| -}
withColor : Ansi.Color.Color -> Element -> Element
withColor =
    Colored


{-| -}
withBackgroundColor : Ansi.Color.Color -> Element -> Element
withBackgroundColor =
    ColoredBackground


{-| -}
withStyle : Style -> Element -> Element
withStyle =
    Styled


{-| -}
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


{-| -}
underline : Element -> Element
underline element =
    Underlined (render element) "─" Nothing


{-| Add underline with custom character
-}
underlineWith : String -> Element -> Element
underlineWith char element =
    Underlined (render element) char Nothing


{-| Add colored underline with custom character and color

    Layoutz.underlineColored "=" Ansi.Color.Red <| Layoutz.text "Error Section"

    Layoutz.underlineColored "~" Ansi.Color.Green <| Layoutz.text "Success"

    Layoutz.underlineColored "─" Ansi.Color.BrightCyan <| Layoutz.text "Info"

-}
underlineColored : String -> Ansi.Color.Color -> Element -> Element
underlineColored char color element =
    Underlined (render element) char (Just color)


{-| -}
center : Element -> Element
center element =
    AutoCenter element


{-| Center element within specified width
-}
centerInWidth : Int -> Element -> Element
centerInWidth targetWidth element =
    Centered (render element) targetWidth


alignLeft : Int -> Element -> Element
alignLeft =
    Debug.todo ""


alignRight : Int -> Element -> Element
alignRight =
    Debug.todo ""


alignCenter : Int -> Element -> Element
alignCenter =
    Debug.todo ""


justify : Int -> Element -> Element
justify =
    Debug.todo ""



--


{-| Render the `Element` to a `String`
-}
render : Element -> String
render element =
    case element of
        Text txt ->
            txt

        UnorderedList items ->
            let
                renderAtLevel : Int -> List Element -> String
                renderAtLevel level itemList =
                    let
                        currentBullet : String
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

                        indent : String
                        indent =
                            String.repeat (level * 2) " "
                    in
                    itemList
                        |> List.map (renderItem level indent currentBullet)
                        |> String.join "\n"

                renderItem : Int -> String -> String -> Element -> String
                renderItem level indent bullet item =
                    case item of
                        UnorderedList nested ->
                            renderAtLevel (level + 1) nested

                        _ ->
                            let
                                content : String
                                content =
                                    render item

                                contentLines : List String
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
                                        firstOutput : String
                                        firstOutput =
                                            indent ++ bullet ++ " " ++ firstLine

                                        restIndent : String
                                        restIndent =
                                            String.repeat (visibleLength indent + visibleLength bullet + 1) " "

                                        restOutput : List String
                                        restOutput =
                                            List.map (\r -> restIndent ++ r) restLines
                                    in
                                    String.join "\n" (firstOutput :: restOutput)
            in
            renderAtLevel 0 items

        OrderedList items ->
            let
                renderAtLevel : Int -> List Element -> String
                renderAtLevel level itemList =
                    let
                        indent : String
                        indent =
                            String.repeat (level * 2) " "
                    in
                    String.join "\n" <| List.indexedMap (renderItem level indent) itemList

                renderItem : Int -> String -> Int -> Element -> String
                renderItem level indent num item =
                    case item of
                        OrderedList nested ->
                            renderAtLevel (level + 1) nested

                        _ ->
                            let
                                numStr : String
                                numStr =
                                    formatNumber level (num + 1) ++ ". "

                                content : String
                                content =
                                    render item

                                contentLines : List String
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
                                        firstOutput : String
                                        firstOutput =
                                            indent ++ numStr ++ firstLine

                                        restIndent : String
                                        restIndent =
                                            String.repeat (visibleLength numStr) " "

                                        restOutput : List String
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
                elementStrings : List String
                elementStrings =
                    List.map render elements

                content : String
                content =
                    String.join "\n" elementStrings

                contentLines : List String
                contentLines =
                    if String.isEmpty content then
                        [ "" ]

                    else
                        String.lines content

                contentWidth : Int
                contentWidth =
                    contentLines
                        |> List.map visibleLength
                        |> List.maximum
                        |> Maybe.withDefault 0

                titleWidth : Int
                titleWidth =
                    if String.isEmpty title then
                        0

                    else
                        visibleLength title + 2

                innerWidth : Int
                innerWidth =
                    max contentWidth titleWidth

                totalWidth : Int
                totalWidth =
                    innerWidth + 4

                { topLeft, topRight, bottomLeft, bottomRight, top, left } =
                    borderChars border

                hChar : String
                hChar =
                    top

                topBorder : String
                topBorder =
                    if String.isEmpty title then
                        topLeft ++ String.repeat (totalWidth - 2) hChar ++ topRight

                    else
                        let
                            titlePadding : Int
                            titlePadding =
                                totalWidth - visibleLength title - 2

                            leftPad : Int
                            leftPad =
                                titlePadding // 2

                            rightPad : Int
                            rightPad =
                                titlePadding - leftPad
                        in
                        topLeft ++ String.repeat leftPad hChar ++ title ++ String.repeat rightPad hChar ++ topRight

                bottomBorder : String
                bottomBorder =
                    bottomLeft ++ String.repeat (totalWidth - 2) hChar ++ bottomRight

                paddedContent : List String
                paddedContent =
                    List.map (\line -> left ++ " " ++ padRight innerWidth line ++ " " ++ left) contentLines
            in
            String.join "\n" (topBorder :: paddedContent ++ [ bottomBorder ])

        StatusCard label content border ->
            let
                labelLines : List String
                labelLines =
                    String.lines label

                contentLines : List String
                contentLines =
                    String.lines content

                allLines : List String
                allLines =
                    labelLines ++ contentLines

                maxWidth : Int
                maxWidth =
                    allLines
                        |> List.map visibleLength
                        |> List.maximum
                        |> Maybe.withDefault 0

                contentWidth : Int
                contentWidth =
                    maxWidth + 2

                { topLeft, topRight, bottomLeft, bottomRight, top, left } =
                    borderChars border

                hChar : String
                hChar =
                    top

                topBorder : String
                topBorder =
                    topLeft ++ String.repeat (contentWidth + 2) hChar ++ topRight

                bottomBorder : String
                bottomBorder =
                    bottomLeft ++ String.repeat (contentWidth + 2) hChar ++ bottomRight

                createCardLine : String -> String
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
                        currentLen : Int
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
                        headerWidths : List Int
                        headerWidths =
                            List.map visibleLength hdrs

                        rowWidths : List (List Int)
                        rowWidths =
                            List.map
                                (List.map
                                    (render
                                        >> String.lines
                                        >> List.map
                                            (\line ->
                                                visibleLength line
                                            )
                                        >> List.maximum
                                        >> Maybe.withDefault 0
                                    )
                                )
                                rws

                        allWidths : List (List Int)
                        allWidths =
                            headerWidths :: rowWidths
                    in
                    List.map (List.maximum >> Maybe.withDefault 0) (transpose allWidths)

                renderTableRow : List Int -> String -> List Element -> List String
                renderTableRow widths vChars rowData =
                    let
                        cellContents : List String
                        cellContents =
                            List.map render rowData

                        cellLines : List (List String)
                        cellLines =
                            List.map String.lines cellContents

                        maxCellHeight : Int
                        maxCellHeight =
                            cellLines
                                |> List.map List.length
                                |> List.maximum
                                |> Maybe.withDefault 1

                        paddedCells : List (List String)
                        paddedCells =
                            List.map2 (padCell maxCellHeight) widths cellLines

                        tableRows : List (List String)
                        tableRows =
                            transpose paddedCells
                    in
                    List.map
                        (\rowCells ->
                            vChars ++ " " ++ String.join (" " ++ vChars ++ " ") rowCells ++ " " ++ vChars
                        )
                        tableRows

                padCell : Int -> Int -> List String -> List String
                padCell cellHeight cellWidth cellLines =
                    let
                        paddedLines : List String
                        paddedLines =
                            cellLines ++ List.repeat (cellHeight - List.length cellLines) ""
                    in
                    List.map (padRight cellWidth) paddedLines

                normalizedRows : List (List Element)
                normalizedRows =
                    rows
                        |> List.map (normalizeRow (List.length headers))

                columnWidths : List Int
                columnWidths =
                    calculateColumnWidths headers normalizedRows

                { topLeft, topRight, bottomLeft, bottomRight, top, left, leftSplit, rightSplit, split } =
                    borderChars border

                hChar : String
                hChar =
                    top

                -- Fixed border construction with proper connectors
                topConnector : String
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

                topParts : List String
                topParts =
                    List.map (\w -> String.repeat w hChar) columnWidths

                topBorder : String
                topBorder =
                    topLeft ++ hChar ++ String.join (hChar ++ topConnector ++ hChar) topParts ++ hChar ++ topRight

                -- Create proper separator with tee connectors
                separatorParts : List String
                separatorParts =
                    List.map (\w -> String.repeat w hChar) columnWidths

                separatorBorder : String
                separatorBorder =
                    leftSplit ++ hChar ++ String.join (hChar ++ split ++ hChar) separatorParts ++ hChar ++ rightSplit

                -- Create proper bottom border with bottom connectors
                bottomConnector : String
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

                bottomParts : List String
                bottomParts =
                    List.map (\w -> String.repeat w hChar) columnWidths

                bottomBorder : String
                bottomBorder =
                    bottomLeft ++ hChar ++ String.join (hChar ++ bottomConnector ++ hChar) bottomParts ++ hChar ++ bottomRight

                -- Create header row
                headerCells : List String
                headerCells =
                    List.map2 padRight columnWidths headers

                headerRow : String
                headerRow =
                    left ++ " " ++ String.join (" " ++ left ++ " ") headerCells ++ " " ++ left

                -- Create data rows
                dataRows : List String
                dataRows =
                    normalizedRows
                        |> List.concatMap (renderTableRow columnWidths left)
            in
            String.join "\n" ([ topBorder, headerRow, separatorBorder ] ++ dataRows ++ [ bottomBorder ])

        LineBreak ->
            "\n"

        Section { title, content, glyph, flankingChars } ->
            let
                header : String
                header =
                    String.repeat flankingChars glyph ++ " " ++ title ++ " " ++ String.repeat flankingChars glyph

                body : String
                body =
                    render (Layout content)
            in
            header ++ "\n" ++ body

        Layout elems ->
            let
                -- Calculate max width of all non-AutoCenter elements
                nonAutoCenterElements : List Element
                nonAutoCenterElements =
                    List.filter (isAutoCenter >> not) elems

                maxWidth : Int
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
                renderedElements : List String
                renderedElements =
                    List.map (renderWithContext maxWidth) elems

                isAutoCenter : Element -> Bool
                isAutoCenter el =
                    case el of
                        AutoCenter _ ->
                            True

                        _ ->
                            False

                renderWithContext : Int -> Element -> String
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
                renderTree : Tree -> String -> Bool -> List Bool -> String
                renderTree (Tree name children) prefix isLast parentPrefixes =
                    let
                        nodeLine : String
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
                    in
                    if List.isEmpty children then
                        nodeLine

                    else
                        let
                            childLines : List String
                            childLines =
                                let
                                    childPrefix : String
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

                                    lastIdx : Int
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
                        nodeLine ++ "\n" ++ String.join "\n" childLines
            in
            renderTree treeData "" True []

        InlineBar label progress ->
            let
                clampedProgress : Float
                clampedProgress =
                    max 0.0 (min 1.0 progress)

                barWidth : number
                barWidth =
                    20

                filledSegments : Int
                filledSegments =
                    floor (clampedProgress * barWidth)

                emptySegments : Int
                emptySegments =
                    barWidth - filledSegments

                bar : String
                bar =
                    String.repeat filledSegments "█" ++ String.repeat emptySegments "─"

                percentage : Int
                percentage =
                    floor (clampedProgress * 100)
            in
            label ++ " [" ++ bar ++ "] " ++ String.fromInt percentage ++ "%"

        Margin prefix elems ->
            let
                content : String
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
                        separator : String
                        separator =
                            if tight then
                                ""

                            else
                                " "

                        elementStrings : List String
                        elementStrings =
                            List.map render elems

                        elementLines : List (List String)
                        elementLines =
                            List.map String.lines elementStrings

                        maxHeight : Int
                        maxHeight =
                            List.map List.length elementLines
                                |> List.maximum
                                |> Maybe.withDefault 0

                        elementWidths : List Int
                        elementWidths =
                            List.map
                                (Maybe.withDefault 0 << List.maximum << List.map visibleLength)
                                elementLines

                        paddedElements : List (List String)
                        paddedElements =
                            List.map2 padElement elementWidths elementLines

                        padElement : Int -> List String -> List String
                        padElement cellWidth linesList =
                            let
                                currentLines : List String
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
                    maxKeyLength : Int
                    maxKeyLength =
                        pairs
                            |> List.map (Tuple.first >> visibleLength)
                            |> List.maximum
                            |> Maybe.withDefault 0

                    alignmentPosition : Int
                    alignmentPosition =
                        maxKeyLength + 2

                    renderPair : Int -> ( String, String ) -> String
                    renderPair alignPos ( key, value ) =
                        let
                            keyWithColon : String
                            keyWithColon =
                                key ++ ":"

                            spacesNeeded : Int
                            spacesNeeded =
                                alignPos - visibleLength keyWithColon

                            padding : String
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
                contentLines : List String
                contentLines =
                    String.lines content

                maxWidth : Int
                maxWidth =
                    if List.isEmpty contentLines then
                        0

                    else
                        contentLines
                            |> List.map visibleLength
                            |> List.maximum
                            |> Maybe.withDefault 0

                repeats : Int
                repeats =
                    maxWidth // String.length underlineChar

                remainder : Int
                remainder =
                    maxWidth |> modBy (String.length underlineChar)

                underlinePart : String
                underlinePart =
                    String.repeat repeats underlineChar ++ String.left remainder underlineChar

                coloredUnderline : String
                coloredUnderline =
                    maybeColor
                        |> Maybe.map (\color -> Ansi.Color.fontColor color underlinePart)
                        |> Maybe.withDefault underlinePart
            in
            content ++ "\n" ++ coloredUnderline

        Spinner label frame style ->
            let
                frames : List String
                frames =
                    spinnerFrames style

                spinChar : String
                spinChar =
                    frames
                        |> List.drop (frame |> modBy (List.length frames))
                        |> List.head
                        |> Maybe.withDefault ""
            in
            if String.isEmpty label then
                spinChar

            else
                spinChar ++ " " ++ label


{-| Spinner style with animation frames
-}
type SpinnerStyle
    = SpinnerDots
    | SpinnerLine
    | SpinnerClock
    | SpinnerBounce


{-| Get animation frames for a spinner style
-}
spinnerFrames : SpinnerStyle -> List String
spinnerFrames style =
    case style of
        SpinnerDots ->
            [ "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" ]

        SpinnerLine ->
            [ "|", "/", "-", "\\" ]

        SpinnerClock ->
            [ "🕐", "🕑", "🕒", "🕓", "🕔", "🕕", "🕖", "🕗", "🕘", "🕙", "🕚", "🕛" ]

        SpinnerBounce ->
            [ "⠁", "⠂", "⠄", "⠂" ]


{-| A loading spinner that can be animated
-}
spinner : String -> Int -> SpinnerStyle -> Element
spinner =
    Spinner



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
        ls : List String
        ls =
            String.lines str

        hasTrailingNewline : Bool
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
        len : Int
        len =
            visibleLength str
    in
    if len >= targetWidth then
        str

    else
        let
            totalPadding : Int
            totalPadding =
                targetWidth - len

            leftPad : String
            leftPad =
                String.repeat (totalPadding // 2) " "

            rightPad : String
            rightPad =
                String.repeat (totalPadding - visibleLength leftPad) " "
        in
        leftPad ++ str ++ rightPad


width : Element -> Int
width element =
    let
        rendered : String
        rendered =
            render element

        renderedLines : List String
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
        rendered : String
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
