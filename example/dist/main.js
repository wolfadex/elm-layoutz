import { createRequire } from "node:module";
const require = createRequire(import.meta.url);

import * as elmLayoutz from "../../src/elm-layoutz.js";
const { Elm } = require("./elm.js");

let app;

elmLayoutz.init();
elmLayoutz.onRawData(function (data) {
  app.ports.stdin.send(data);
});

switch (process.argv[2]) {
  case "Counter":
    app = Elm.Counter.init();
    break;
  case "Readme":
    app = Elm.Readme.init();
    break;
  case "TaskList":
    app = Elm.TaskList.init();
    break;
}

app.ports.stdout.subscribe(function (data) {
  elmLayoutz.writeToStdout(data);
});

app.ports.exit.subscribe(function (code) {
  process.exit(code);
});

function requestAnimationFrame(f) {
  setImmediate(() => f(Date.now()));
}
function tick(time) {
  app.ports.onTick.send(time);
  requestAnimationFrame(tick);
}

requestAnimationFrame(tick);
