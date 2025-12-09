import * as elmLayoutz from "../../src/elm-layoutz.js";
import { Elm } from "./elm.js";

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
