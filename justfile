example-build:
    cd example && wrap make src/Counter.elm src/Readme.elm src/TaskList.elm src/Spinner.elm --output=dist/elm.js

example-run-counter: example-build
    node example Counter

example-run-readme: example-build
    node example Readme

example-run-tasklist: example-build
    node example TaskList

example-run-spinner: example-build
    node example Spinner
