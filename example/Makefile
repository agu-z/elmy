all:
	elm make --optimize --output=app.js src/Main.elm 
	echo "Elm.Main.init({ flags: {} }).ports.render.subscribe(elmyRender);" >> app.js
	cp app.js ios/ElmyExample
	cp app.js android/ElmyExample/app/src/main/res/raw/
