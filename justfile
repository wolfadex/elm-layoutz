example-build:
    cd example && \
        wrap make src/Counter.elm --output=dist/elm.js && \
        awk '{gsub(/(this)/, "(globalThis)")}1' ./dist/elm.js > ./dist/elm.tmp && \
        mv ./dist/elm.tmp ./dist/elm.js

example-run: example-build
    node example
