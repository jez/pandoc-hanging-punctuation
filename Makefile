index.html: Makefile input.md hanging-punctuation.lua
	/opt/homebrew/bin/pandoc -f markdown -t html input.md \
		--lua-filter=./hanging-punctuation.lua \
		--wrap=preserve \
		--standalone \
		--css typeset.css \
		--css other.css > index.html

input.json: Makefile input.md
	/opt/homebrew/bin/pandoc -f markdown -t json input.md | jq . > input.json

output.json: Makefile input.md hanging-punctuation.lua
	/opt/homebrew/bin/pandoc -f markdown -t json input.md \
		--lua-filter=./hanging-punctuation.lua | jq . > output.json
