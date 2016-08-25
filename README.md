p6-PDF-Style
============
Experimental PDF composition with HTML like coordinate systems and text/image markup; CSS like styling rules and box model.

** Proposed ** See #1

```
use v6;
use PDF::Content::PDF;
use Style::Viewport::PDF :pt;
use CSS::Declarations;
use CSS::Declarations::Units;

my $css = CSS::Declarations.new: :style("font-family:Helvetica; width:250pt; height:80pt; position:absolute; top:20pt; left:20pt; border 1pt dashed green");

my $pdf = PDF::Content::PDF.new;
my $page = $pdf.add-page;
$page.media-box = [0, 0, pt($vp.width), pt($vp.height) ];
my $vp = Style::Viewport::PDF.new :media($page);

my $para = q:to"--ENOUGH!!--".lines.join: ' ';
    Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt
    ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco.
    --ENOUGH!!--

my $box = $vp.text( $para, :$css );

$css.top += $box.height;
$css.border-color = :keyw<green>;

# nyi - images
$vp.image("t/sample.png", :$css);

$pdf.save-as: "t/example.pdf";
```

This will be more familiar to those from an HTML background and may form a useful basis for HTML rendering.

## CSS Property todo list:
Group|Property|Notes|To-do
---|---|---|---
background||NYI
  |background-color||NYI
  |background-position||NYI
  |background-repeat||NYI
  |background-attachment||NYI
border (boxed)|
  |border-color||
  |border-spacing||NYI
  |border-style|'dotted', 'dashed'|Other styles. Play better with border-width
Edges|
  |border-width
  |margin
  |padding
Position|
  |bottom, top, left, right
  |height, max-height, min-height
  |width, max-width, min-width
  |clip||NYI
  |font-family
  |font-style
  |font-size||Handle 100, 200, 300, etc.
  |font-kerning
  |font-weight
  |letter-spacing||NYI
  |line-height||Test/review
  |text-align
  |text-decoration||NYI
  |text-indent||NYI
  |text-transform||NYI
  |word-spacing||NYI
  
### General
- percentage values are NYI, e.g. on borders

### CSS Property Shortlist
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

## Restrictions

- support for core fonts only, latin-1 encoding
- basic image rendering and placement (PNG, GIF and JPEG)
- support for a small subset of available css 2.1 properties
- some ability to import base template pdf pages (viewport background-image)
- very basic HTML support, e.g. `<p>, <div> & <span>` elements

