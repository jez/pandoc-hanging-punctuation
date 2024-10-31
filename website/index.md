---
# vim:ft=liquid
# liquid_subtype=pandoc
layout: 'index'
title: 'Hanging Punctuation in Pandoc'
subtitle: "A lua filter for Pandoc which allows curly quotes to hang into the
margin."
author: "@jez"
author_url: 'https://github.com/jez'
date: "2024-10-30"
# Always regenerate, even with --incremental
regenerate: true
---

This project provides a [lua filter] for [Pandoc] along with some CSS styles
which together allow curly quotes to hang into the margin. Here's an example:

[lua filter]: https://pandoc.org/lua-filters.html
[Pandoc]: https://pandoc.org

- - - - -

"How do you call among you the little mouse, the mouse that jumps?" Paul asked,
remembering the pop-hop of motion at Tuono Basin. He illustrated with one hand.
A chuckle sounded through the troop. "We call that one muad'dib," Stilgar said.

— Frank Herbert, _Dune_

- - - - -

Note how the `“` on the first line hangs into the margin. But also, depending on
the screen width, the mid-paragraph quote starting `“We ...` may also hang
into the margin:

::: left-align-caption
![The same quote, at a small screen size](/pandoc-hanging-punctuation/assets/img/light/dune-quote.png){style="max-width:456px;"}
:::

![The same quote, at a small screen size](/pandoc-hanging-punctuation/assets/img/dark/dune-quote.png){style="max-width:453px;"}

This effect is not possible with the [`hanging-punctuation`] CSS property.
Safari supports it, but only for the very first quotation mark in a block. All
other browsers do not support it.

[`hanging-punctuation`]: https://developer.mozilla.org/en-US/docs/Web/CSS/hanging-punctuation

By contrast, this filter allows quotation characters to hang into the margin
even in the middle of body text, and works in all browsers.

For more, read about [hanging
punctuation](https://en.wikipedia.org/wiki/Hanging_punctuation) on Wikipedia.

# Usage

1.  Download the `hanging-punctuation.lua` file:

    :::{.wide}
    ```{.bash}
    curl -sSLO https://raw.githubusercontent.com/jez/pandoc-hanging-punctuation/refs/heads/master/hanging-punctuation.lua
    ```
    :::

1.  Download the `hanging-punctuation.css` file:

    :::{.wide}
    ```{.bash}
    curl -sSLO https://raw.githubusercontent.com/jez/pandoc-hanging-punctuation/refs/heads/master/hanging-punctuation.css
    ```
    :::

1.  Pass these files when invoking `pandoc`:

    ```bash
    pandoc -f markdown -t html index.md \
      --standalone \
      --lua-filter=./hanging-punctuation.lua \
      --css ./hanging-punctuation.css > index.html
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
    /* -- hanging-punctuation.css -- */
    :root {
      /**
       * These widths will vary with font-family, font-weight, etc.
       * TODO: Customize these values as needed
       */
      --single-quote-width: 0.275em;
      --double-quote-width: 0.44em;
    }

    /* ... */
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

## Caveats

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

# Inspiration

This filter is heavily inspired by [Typeset], "An HTML pre-processor for web
typography." Compared to Typeset, this project:

- Requires no JavaScript library (nor JavaScript build process)
- Uses Pandoc's internal document AST, instead of the DOM, which makes certain
  edge cases more robust.
- Does not need to handle straight → curly quotation mark conversion nor en- and
  em-dash conversion, because Pandoc handles those.

Typeset includes other features which could be handled separately if desired
(like auto-soft-hyphenation and certain other punctuation substitutions). The
markup structure in this project is borrowed from Typeset.

It's also inspired by [Dropbox Paper], which includes support for hanging
punctuation, and has inspired my other writing-focused tools. In particular,
this website is uses my [Pandoc Markdown CSS Theme][pandoc-css], which draws
heavy inspiration from the look of Dropbox Paper.

[Typeset]: https://typeset.lllllllllllllllll.com/
[Dropbox Paper]: https://paper.dropbox.com/
[pandoc-css]: https://jez.io/pandoc-markdown-css-theme/
[q-tags]: https://pandoc.org/MANUAL.html#option--html-q-tags[
[smart]: https://pandoc.org/MANUAL.html#extension-smart

\

\

# Testing

::: {style="border: 1px solid red;"}

| Hello
| "Hello"
| Hello
| 'Hello'
| Hello

:::


<p class="signoff">
  [↑ Back to top](#posts)
</p>

<a href="https://github.com/jez/pandoc-hanging-punctuation" class="github-corner" aria-label="View source on GitHub"><svg width="80" height="80" viewBox="0 0 250 250" style="fill:#151513; color:#fff; position: absolute; top: 0; border: 0; right: 0;" aria-hidden="true"><path d="M0,0 L115,115 L130,115 L142,142 L250,250 L250,0 Z"></path><path d="M128.3,109.0 C113.8,99.7 119.0,89.6 119.0,89.6 C122.0,82.7 120.5,78.6 120.5,78.6 C119.2,72.0 123.4,76.3 123.4,76.3 C127.3,80.9 125.5,87.3 125.5,87.3 C122.9,97.6 130.6,101.9 134.4,103.2" fill="currentColor" style="transform-origin: 130px 106px;" class="octo-arm"></path><path d="M115.0,115.0 C114.9,115.1 118.7,116.5 119.8,115.4 L133.7,101.6 C136.9,99.2 139.9,98.4 142.2,98.6 C133.8,88.0 127.5,74.4 143.8,58.0 C148.5,53.4 154.0,51.2 159.7,51.0 C160.3,49.4 163.2,43.6 171.4,40.1 C171.4,40.1 176.1,42.5 178.8,56.2 C183.1,58.6 187.2,61.8 190.9,65.4 C194.5,69.0 197.7,73.2 200.1,77.6 C213.8,80.2 216.3,84.9 216.3,84.9 C212.7,93.1 206.9,96.0 205.4,96.6 C205.1,102.4 203.0,107.8 198.3,112.5 C181.9,128.9 168.3,122.5 157.7,114.1 C157.9,116.9 156.7,120.9 152.7,124.9 L141.0,136.5 C139.8,137.7 141.6,141.9 141.8,141.8 Z" fill="currentColor" class="octo-body"></path></svg></a><style>.github-corner:hover .octo-arm{animation:octocat-wave 560ms ease-in-out}@keyframes octocat-wave{0%,100%{transform:rotate(0)}20%,60%{transform:rotate(-25deg)}40%,80%{transform:rotate(10deg)}}@media (max-width:500px){.github-corner:hover .octo-arm{animation:none}.github-corner .octo-arm{animation:octocat-wave 560ms ease-in-out}}</style>
