all:
	elm make --output=app.js src/Main.elm 
	echo "var ElmyApp = Elm.Main.init({ flags: {} }); ElmyApp.ports.tick.subscribe(elmyTick);" >> app.js
	cp app.js ios/ElmyExample
	cp app.js android/ElmyExample/app/src/main/res/raw/
