# hanging-punctuation.lua

A [lua filter] for [Pandoc], which allows curly quotes to hang into the margin.

[lua filter]: https://pandoc.org/lua-filters.html
[Pandoc]: https://pandoc.org

## Usage

1.  Download the `hanging-punctuation.lua` file:

    ```bash
    curl -sSLO https://raw.githubusercontent.com/jez/pandoc-hanging-punctuation/refs/heads/master/hanging-punctuation.lua
    ```

1.  Download the `hanging-punctuation.css` file:

    ```bash
    curl -sSLO https://raw.githubusercontent.com/jez/pandoc-hanging-punctuation/refs/heads/master/hanging-punctuation.css
    ```

1.  Pass these files when invoking `pandoc`:

    ```bash
    pandoc -f markdown -t html index.md \
      --standalone \
      --lua-filter=./hanging-punctuation.lua \
      --css typeset.css > index.html
    ```

    The input must either use `‘` and `“` quotes directly, or have the [`smart`
    extension][smart] enabled.

    The `smart` extension is on by default in Pandoc's `markdown` input format,
    but off by default in others, including the `commonmark` format. Enable it by
    passing `+smart` to the format when invoking `pandoc`, like `-f
    commonmark+smart`.

    See the Pandoc docs for more:

    - [`--css`](https://pandoc.org/MANUAL.html#option--css)
    - [`--lua-filter`](https://pandoc.org/MANUAL.html#option--lua-filter)
    - [`+smart`][smart]

1.  Modify the `hanging-punctuation.css` file to set the two root CSS variables:

    ```css
    :root {
      /**
       * These widths will vary with font-family, font-weight, etc.
       * TODO: Customize these values as needed
       */
      --single-quote-width: 0.33em;
      --double-quote-width: 0.44em;
    }
    ```

    These variables declare how big `‘` and `“` characters are in the chosen
    font. Different font settings, like the family and weight, will affect the
    width.

    To determine a value for these variables, use a document like this:

    ```md
    ---
    title: test
    ---

    Hello\
    "Hello"\
    Hello\
    'Hello'\
    Hello
    ```

    Render this markdown to HTML, then use the browser's developer tools to
    vertically align all the `H` characters.

    As a a trick, on some operating systems you can use the system screenshot
    tool as a quick way to check if things are aligned and measure pixels
    distances on the screen.

1.  Ensure that no other CSS in the page sets the `hanging-punctuation`
    property.

    Either edit that CSS to remove mentions of it, or write CSS to forcibly
    override any inherited `hanging-punctuation` settings.

### Caveats

- Only HTML output has been tested. Other Pandoc output formats, like LaTeX or
  Microsoft Word, are not supported (though it may be possible to use this tool
  as a starting point to support other formats).

- This overrules [the `--html-q-tags=true` option][q-tags] affecting the HTML
  writer. No `<q>` tags will be produced in the output, even with that option
  passed, if this filter is used.

  (Why? Because this filter eliminates `Quoted` nodes in Pandoc's internal AST
  in the course of working, which otherwise power the HTML writer's `<q>` tag
  support.)

- Hanging is disabled inside list items and table cells, even if there would
  otherwise be enough space in the margin to hang the punctuation.

  To change this, edit the relevant lines in `hanging-punctuation.css` as
  desired.

## Implementation

Input like this:

```markdown
“Some text”
```

is translated to this:

```
<span class="pull-double">“</span>Some text”
```

if at the start of a line, or this if in the middle of a line:

```
<span class="push-double"></span><span class="pull-double">“</span>Some text”
```

These `push-*` and `pull-*` classes are then styled to achieve the hanging
effect. See [index.html](index.html) for sample rendered output.

## Future features?

- Add support for partially hanging individual letters into the margins (for
  example, `T, V, W, Y, O, C, A, o, c`).

- Support for hanging punctuation in `Cite` (citation text) and `Image` (caption
  text) nodes.


## Inspiration

This filter is heavily inspired by [Typeset], "An HTML pre-processor for web
typography." Typeset includes other features that are either obviated by Pandoc
(like auto straight → curly quotation marks, as well as en- and em-dashes), or
that I think could be handled separately if desired (like auto-soft-hyphenation
and certain punctuation substitutions). The markup structure are taken from
Typeset.

It's also inspired by [Dropbox Paper], which includes support for hanging
punctuation, and has inspired [my other writing-focused tools][pandoc-css].

<!-- TODO(jez) InDesign, some sort of doc for the idea of hanging punctuation,
LaTeX? -->

[Typeset]: https://typeset.lllllllllllllllll.com/
[Dropbox Paper]: https://paper.dropbox.com/
[pandoc-css]: https://jez.io/pandoc-markdown-css-theme/
[q-tags]: https://pandoc.org/MANUAL.html#option--html-q-tags[
[smart]: https://pandoc.org/MANUAL.html#extension-smart
