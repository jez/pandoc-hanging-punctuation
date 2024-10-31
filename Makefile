index.html: Makefile input.md hanging-punctuation.lua
	pandoc \
		-f markdown -t html input.md \
		--lua-filter=./hanging-punctuation.lua \
		--wrap=preserve \
		--standalone \
		--css ./hanging-punctuation.css \
		--css other.css > index.html

input.json: Makefile input.md
	pandoc \
		-f markdown -t json input.md | jq . > input.json

output.json: Makefile input.md hanging-punctuation.lua
	pandoc \
		-f markdown -t json input.md \
		--lua-filter=./hanging-punctuation.lua | jq . > output.json
