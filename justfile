example-build:
    cd example && wrap make src/Counter.elm src/Readme.elm src/TaskList.elm --output=dist/elm.js

example-run-counter: example-build
    node example Counter

example-run-readme: example-build
    node example Readme

example-run-tasklist: example-build
    node example TaskList
