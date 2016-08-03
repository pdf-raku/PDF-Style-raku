p6-PDF-Style
============
Experimental PDF composition with HTML like coordinate systems and text/image markup; CSS like styling rules and box model.

This will be more familiar to those from an HTML background and may form a useful basis for HTML rendering.

Initial version likely to have:
- support for core fonts only, latin-1 encoding
- basic image rendering and placement (PNG, GIF and JPEG)
- support for a small subset of available css 2.1 properties
- some ability to import base template pdf pages (viewport background-image)
- very basic HTML support, e.g. `<p>, <div> & <span>` elements

CSS Property todo list:
- background
  - background-color
  - background-position
  - background-repeat
  - background-attachment: does the background scroll?
- border (border-top, border-left, border-right, border-bottom)
  - border-color (border-top-color etc)
  - border-spacing (border-top-spacing, etc)
  - border-style (border-top-style etc)
  - bottom, top, left, right
- clip
- font-family
- font-style
- font-kerning
- font-weight
- height, max-height, min-height
- width, max-width, min-width
- letter-spacing
- line-height
- margin, margin-left, margin-right, margin-top, margin-bottom
- padding, padding-top, padding-left, padding-right, padding-bottom
- text-align
- text-decoration
- text-indent
- text-transform
- word-spacing

CSS Property Shortlist
- content
- direction
- display
- font-variant
- empty-cells
- float
- list-style, list-style-image, list-style-position, list-style-type
- outline, outline-width, outline-style, outline-color
- page-break-before, page-break-after, page-break-inside
- overflow
- unicode-bidi
- table-layout
- visibility
- white-spacing

### Nice to have:
Fonts:
- font-synthesis
- @font-face

CSS Transforms http://dev.w3.org/csswg/css-transforms/#transform
- transform
- transform-origin

Tagged PDF!
