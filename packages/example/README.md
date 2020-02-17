# uiasm-example

## Compiling

```console
$ elm make --optimize --output=ios/UiAsmExample/UiAsmExample/app.js src/Main.elm && echo "Elm.Main.init({ flags: {} }).ports.render.subscribe(swiftUiAsmRender);" >> ios/UiAsmExample/UiAsmExample/app.js
```
