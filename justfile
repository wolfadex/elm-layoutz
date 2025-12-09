example-build:
    # nodemon --exec 'elm-esm make src/AnsiExample.elm --output=dist/example-elm-ansi.js' --watch ../src --watch src -e elm",
    cd example && elm-esm make src/Counter.elm --output=dist/elm.js

example-run: example-build
    node example
