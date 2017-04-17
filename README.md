p6-PDF-Style
============
Experimental PDF composition with HTML positioning and CSS styling rules and box model.

```
use v6;
use PDF::Lite;
use PDF::Style::Viewport;
use CSS::Declarations;
use CSS::Declarations::Units :pt, :ops;

my $pdf = PDF::Lite.new;
my $vp = PDF::Style::Viewport.new: :width(420pt), :height(595), :style("background-color: blue; opacity: 0.2;");
my $page = $vp.add-page($pdf);

my $css = CSS::Declarations.new: :style("font-family:Helvetica; width:250pt; height:80pt; position:absolute; top:20pt; left:20pt; border: 1pt dashed green; padding: 2pt");

my $text = q:to"--ENOUGH!!--".lines.join: ' ';
    Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt
    ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco.
    --ENOUGH!!--

my $box = $vp.box( :$text, :$css );
$box.render($page);

# make some styling adjustments
$css.border-color = 'red';
# todo: padding adjustments
$css.top  ➕= ($box.height('padding') + 5)pt;
$css.delete('height');

my $image = "t/images/snoopy-happy-dance.jpg";
$vp.box(:$image, :$css).render($page);

$pdf.save-as: "t/example.pdf";
```

This will be more familiar to those from an HTML background and may form a useful basis for HTML rendering.

## CSS Property todo list:
Group|Property|Notes|To-do
---|---|---|---
background||
  |background-color||
  |background-image||
  |background-repeat||
  |background-position||
border (boxed)|
  |border-color||
  |border-style|'dotted', 'dashed'|Other styles. Play better with border-width
  |border-width
Edges|
  |margin
  |padding
Position|
  |bottom, top, left, right
  |height, max-height, min-height
  |width, max-width, min-width
  |font-family
  |font-style
  |font-size
  |font-kerning
  |font-stretch
  |font-weight||
  |color||
  |letter-spacing||
  |line-height||
  |opacity||
  |text-align||
  |text-decoration||NYI
  |text-indent||NYI
  |text-transform||NYI
  |vertical-align||'top', 'center', 'bottom' only
  |word-spacing||
  
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
- support for a modest subset of available css 2.1 properties
- some ability to import base template pdf pages (viewport background-image)

