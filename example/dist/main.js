import { createRequire } from "node:module";
const require = createRequire(import.meta.url);

import * as elmLayoutz from "../../src/elm-layoutz.js";
require("./elm.js");

let app;

elmLayoutz.init();
elmLayoutz.onRawData(function (data) {
  app.ports.stdin.send(data);
});

app = Elm.Counter.init();

app.ports.stdout.subscribe(function (data) {
  elmLayoutz.writeToStdout(data);
});

app.ports.exit.subscribe(function (code) {
  process.exit(code);
});
