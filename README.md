# elm-layoutz

Simple, beautiful CLI output for Elm 🪶

Build declarative and composable sections, trees, tables, dashboards, and interactive Elm-style TUIs. Easily create new primitives (no component-library limitations).


## Features
- Rich text formatting: alignment, underlines, padding, margins
- Lists, trees, tables, charts, spinners...
- ANSI colors and wide character support
- Easily create new primitives (no component-library limitations)

![TaskList](https://raw.githubusercontent.com/wolfadex/elm-layoutz/refs/heads/main/assets/TaskList.webp)
![SimpleGame](https://raw.githubusercontent.com/wolfadex/elm-layoutz/refs/heads/main/assets/SimpleGame.webp)

## Table of Contents
- [Quickstart](#quickstart)
- [Why layoutz?](#why-layoutz)
- [Core Concepts](#core-concepts)
- [Elements](#elements)
- [Border Styles](#border-styles)
- [Colors](#colors-ansi-support)
- [Styles](#styles-ansi-support)
- [Custom Components](#custom-components)
- [Interactive Apps](#interactive-apps)


## Quickstart

**(1/2) Static rendering** - Beautiful, compositional strings:

```elm
import Ansi.Color -- from wolfadex/elm-ansi
import Layoutz

demo =
    Layoutz.layout
        [ Layoutz.center <|
            Layoutz.row 
                [ Layoutz.withStyle Layoutz.StyleBold <| Layoutz.text "Layoutz"
                , Layoutz.withColor Ansi.Color.Cyan <| Layoutz.underline "ˆ" <| Layoutz.text "DEMO"
                ]
        , Layoutz.br
        , Layoutz.row
            [ Layoutz.statusCard "Users" "1.2K"
            , Layoutz.withBorder Layoutz.BorderDouble <| Layoutz.statusCard "API" "UP"
            , Layoutz.withColor Ansi.Color.Red <| Layoutz.withBorder Layoutz.BorderThick <| Layoutz.statusCard "CPU" "23%"
            , Layoutz.withStyle Layoutz.StyleReverse <|
                Layoutz.withBorder Layoutz.BorderRound <|
                    Layoutz.table
                        ["Name", "Role", "Skills"] 
               	        [ [ Layoutz.text "Gegard"
                          , Layoutz.text "Pugilist"
                          , Layoutz.ul
                              [ Layoutz.text "Armenian"
                              , Layoutz.ul [ Layoutz.text "bad", Layoutz.ul [ Layoutz.text"man" ] ]
                              ]
                          ]
                        , [ Layoutz.text "Eve", Layoutz.text "QA", Layoutz.text "Testing"]
                        ]
            ]
        ]

render demo
```

![Readme](https://raw.githubusercontent.com/wolfadex/elm-layoutz/refs/heads/main/assets/Readme.png)

**(2/2) Interactive apps** - Build Elm-style TUI's:

```elm
import Ansi.Cursor
import Layoutz
import Ports -- user defined, see examples

type Msg = Increment | Decrement

init : () -> ( Model, Cmd Msg )
init () =
    render ( { count = 0 }, Cmd.none )

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
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
            |> (\rendered -> Ansi.Cursor.hide ++ Ansi.clearScreen ++ rendered)
            |> Ports.stdout
        , cmd
        ]
    )
```

## Core concepts
- Every piece of content is an `Element`
- Elements are **immutable** and **composable** - build complex layouts by combining simple elements
- A `layout` arranges elements **vertically**:
```elm
Layoutz.layout [elem1, elem2, elem3]  -- Joins with "\n"
```
Call `Layoutz.render` on any element to get a string

The power comes from **uniform composition** - since everything is an `Element`, everything can be combined.


## Elements

### Text
```elm
text "Simple text"
```
```
Simple text
```

### Line Break
Add line breaks with `br`:
```elm
layout [text "Line 1", br, text "Line 2"]
```
```
Line 1

Line 2
```

### Section: `section`
```elm
section "Config" [keyValue [("env", "prod")]]
section' "-" "Status" [keyValue [("health", "ok")]]
section'' "#" "Report" 5 [keyValue [("items", "42")]]
```
```
=== Config ===
env: prod

--- Status ---
health: ok

##### Report #####
items: 42
```

### Layout (vertical): `layout`
```elm
layout [text "First",text "Second",text "Third"]
```
```
First
Second
Third
```

### Row (horizontal): `row`
Arrange elements side-by-side horizontally:
```elm
row [text "Left",text "Middle",text "Right"]
```
```
Left Middle Right
```

Multi-line elements are aligned at the top:
```elm
row 
  [ layout [text "Left",text "Column"]
  , layout [text "Middle",text "Column"]
  , layout [text "Right",text "Column"]
  ]
```

### Tight Row: `tightRow`
Like `row`, but with no spacing between elements (useful for gradients and progress bars):
```elm
tightRow [withColor Ansi.Color.Red <| text "█", withColor Ansi.Color.Green $<| text "█", withColor Ansi.Color.Blue <| text "█"]
```
```
███
```

### Text alignment: `alignLeft`, `alignRight`, `alignCenter`, `justify`
Align text within a specified width:
```elm
layout
  [ alignLeft 40 "Left aligned"
  , alignCenter 40 "Centered"
  , alignRight 40 "Right aligned"
  , justify 40 "This text is justified evenly"
  ]
```
```
Left aligned                            
               Centered                 
                           Right aligned
This  text  is  justified         evenly
```

### Horizontal rule: `hr`
```elm
hr
hr' "~"
hr'' "-" 10
```
```
──────────────────────────────────────────────────
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
----------
```

### Vertical rule: `vr`
```elm
row [vr, vr' "║", vr'' "x" 5]
```
```
│ ║ x
│ ║ x
│ ║ x
│ ║ x
│ ║ x
│ ║
│ ║
│ ║
│ ║
│ ║
```

### Key-value pairs: `keyValue`
```elm
keyValue [("name", "Alice"), ("role", "admin")]
```
```
name: Alice
role: admin
```

### Table: `table`
Tables automatically handle alignment and borders:
```elm
table ["Name", "Age", "City"] 
  [ [text "Alice", text "30", text "New York"]
  , [text "Bob", text "25", text ""]
  , [text "Charlie", text "35", text "London"]
  ]
```
```
┌─────────┬─────┬─────────┐
│ Name    │ Age │ City    │
├─────────┼─────┼─────────┤
│ Alice   │ 30  │ New York│
│ Bob     │ 25  │         │
│ Charlie │ 35  │ London  │
└─────────┴─────┴─────────┘
```

### Unordered Lists: `ul`
Clean unordered lists with automatic nesting:
```elm
ul [text "Feature A", text "Feature B", text "Feature C"]
```
```
• Feature A
• Feature B
• Feature C
```

Nested lists with auto-styling:
```elm
ul [ text "Backend"
   , ul [text "API", text "Database"]
   , text "Frontend"
   , ul [text "Components", ul [text "Header", ul [text "Footer"]]]
   ]
```
```
• Backend
  ◦ API
  ◦ Database
• Frontend
  ◦ Components
    ▪ Header
      • Footer
```

### Ordered Lists: `ol`
Numbered lists with automatic nesting:
```elm
ol [text "First step", text "Second step", text "Third step"]
```
```
1. First step
2. Second step
3. Third step
```

Nested ordered lists with automatic style cycling (numbers → letters → roman numerals):
```elm
ol [ text "Setup"
   , ol [text "Install dependencies", text "Configure", ol [text "Check version"]]
   , text "Build"
   , text "Deploy"
   ]
```
```
1. Setup
  a. Install dependencies
  b. Configure
    i. Check version
2. Build
3. Deploy
```

### Underline: `underline`
Add underlines to any element:
```elm
underline <| text "Important Title"
underline' "=" <| text "Custom"  -- Use text for custom underline char
```
```
Important Title
───────────────

Custom
══════
```

### Box: `box`
With title:
```elm
box "Summary" [keyValue [("total", "42")]]
```
```
┌──Summary───┐
│ total: 42  │
└────────────┘
```

Without title:
```elm
box "" [keyValue [("total", "42")]]
```
```
┌────────────┐
│ total: 42  │
└────────────┘
```

### Status card: `statusCard`
```elm
statusCard "CPU" "45%"
```
```
┌───────┐
│ CPU   │
│ 45%   │
└───────┘
```

### Progress bar: `inlineBar`
```elm
inlineBar "Download" 0.75
```
```
Download [███████████████─────] 75%
```

### Tree: `tree`
```elm
tree "Project" 
  [ branch "src" 
      [ leaf "main.hs"
      , leaf "test.hs"
      ]
  , branch "docs"
      [ leaf "README.md"
      ]
  ]
```
```
Project
├── src
│   ├── main.hs
│   └── test.hs
└── docs
    └── README.md
```

### Chart: `chart`
```elm
chart [("Web", 10), ("Mobile", 20), ("API", 15)]
```
```
Web    │████████████████████ 10
Mobile │████████████████████████████████████████ 20
API    │██████████████████████████████ 15
```

### Padding: `pad`
Add uniform padding around any element:
```elm
pad 2 <| text "content"
```
```
        
        
  content  
        
        
```

### Spinners: `spinner`
Animated loading spinners for TUI apps:
```elm
spinner "Loading..." frameNum SpinnerDots
spinner "Processing" frameNum SpinnerLine
spinner "Working" frameNum SpinnerClock
spinner "Thinking" frameNum SpinnerBounce
```

Styles:
- **`SpinnerDots`** - Braille dot spinner: ⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏
- **`SpinnerLine`** - Classic line spinner: | / - \
- **`SpinnerClock`** - Clock face spinner: 🕐 🕑 🕒 ...
- **`SpinnerBounce`** - Bouncing dots: ⠁ ⠂ ⠄ ⠂

Increment the frame number on each render to animate:
```elm
-- In your app state, track a frame counter
type alias Model = { spinnerFrame : Int, ... }

-- In your view function
spinner "Loading" model.spinnerFrame SpinnerDots

-- In your update function (triggered by a tick or key press)
{ model | spinnerFrame = model.spinnerFrame + 1 }
```

With colors:
```elm
withColor Ansi.Color.Green <| spinner "Success!" frame SpinnerDots
withColor Ansi.Color.Yellow <| spinner "Warning" frame SpinnerLine
```

### Centering: `center`
Smart auto-centering and manual width:
```elm
center <| text "Auto-centered"     -- Uses layout context
center' 20 <| text "Manual width"  -- Fixed width
```
```
        Auto-centered        

    Manual width    
```

### Margin: `margin`
Add prefix margins to elements for compiler-style error messages:

```elm
margin "[error]"
  [ text "Ooops"
  , text ""
  , row [ text "result :: Int = "
        , underline' "^" <| text "getString"
        ]
  , text "Expected Int, found String"
  ]
```
```
[error] Ooops
[error]
[error] result :: Int =  getString
[error]                  ^^^^^^^^^
[error] Expected Int, found String
```

## Border Styles
Elements like `box`, `table`, and `statusCard` support different border styles:

**BorderNormal** (default):
```elm
box "Title" [text "content"]
```
```
┌──Title──┐
│ content │
└─────────┘
```

**BorderDouble**:
```elm
withBorder BorderDouble <| statusCard "API" "UP"
```
```
╔═══════╗
║ API   ║
║ UP    ║
╚═══════╝
```

**BorderThick**:
```elm
withBorder BorderThick <| table ["Name"] [["Alice"]]
```
```
┏━━━━━━━┓
┃ Name  ┃
┣━━━━━━━┫
┃ Alice ┃
┗━━━━━━━┛
```

**BorderRound**:
```elm
withBorder BorderRound <| box "Info" ["content"]
```
```
╭──Info───╮
│ content │
╰─────────╯
```

**BorderNone** (invisible borders):
```elm
withBorder BorderNone <| box "Info" ["content"]
```
```
  Info   
 content 
         
```

## Colors (ANSI Support)

Add ANSI colors to any element using [wolfadex/elm-ansi](https://package.elm-lang.org/packages/wolfadex/elm-ansi/latest/):

```elm
layout[
  withColor Ansi.Color.Red <| text "The quick brown fox...",
  withColor Ansi.Color.BrightCyan <| text "The quick brown fox...",
  underlineColored "~" Ansi.Color.Red <| text "The quick brown fox...",
  margin "[INFO]" [withColor Ansi.Color.Cyan <| text "The quick brown fox..."]
]
```

## Styles (ANSI Support)

Add ANSI styles to any element:

```elm
layout[
  withStyle StyleBold <| text "The quick brown fox...",
  withColor ColorRed <| withStyle StyleBold <| text "The quick brown fox...",
  withBackgroundColor Ansi.Color.White <| withStyle StyleItalic <| text "The quick brown fox..."
]
```

**Styles:**
- `StyleBold` `StyleDim` `StyleItalic` `StyleUnderline`
- `StyleBlink` `StyleHidden` `StyleStrikethrough`
- `StyleNoStyle` *(for conditional formatting)*

```elm
layout[
  withStyle (StyleCombined [StyleBold, StyleItalic, StyleUnderline]) <| text "The quick brown fox..."
]
```

You can also combine colors and styles:

```elm
withColor Ansi.Color.BrightYellow <| withStyle (StyleCombined [StyleBold, StyleItalic]) <| text "The quick brown fox..."
```

## Custom Components

Create your own components by implementing the `Element` typeclass

```elm
import Layoutz

-- instance Element Square where
--   renderElement (Square size) 
--     | size < 2 = ""
--     | otherwise = intercalate "\n" (top : middle ++ [bottom])
--     where
--       w = size * 2 - 2
--       top = "┌" ++ replicate w '─' ++ "┐"
--       middle = replicate (size - 2) ("│" ++ replicate w ' ' ++ "│")
--       bottom = "└" ++ replicate w '─' ++ "┘"

-- Helper to avoid wrapping with L
square : Int -> Layoutz.Element
square n = Layoutz.custom (Debug.todo "")

-- Use it like any other element
putStrLn <| render <| row
  [ square 3
  , square 5
  , square 7
  ]
```
```
┌────┐ ┌────────┐ ┌────────────┐
│    │ │        │ │            │
└────┘ │        │ │            │
       │        │ │            │
       └────────┘ │            │
                  │            │
                  └────────────┘
```

## Interactive Apps

Build **terminal applications** with the example TUI runtime.

## Inspiration
- Original Scala [layoutz](https://github.com/mattlianje/layoutz)
