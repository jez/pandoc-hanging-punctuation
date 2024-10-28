index.html: input.md hanging-punctuation.lua
	pandoc -f markdown -t html input.md \
		--lua-filter=./hanging-punctuation.lua \
		--standalone \
		--css typeset.css \
		--css other.css > index.html
