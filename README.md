PDF-Style-p6
============
This module implements simple CSS styling and placement of PDF image form, or text elements.


```
use v6;
use PDF::Lite;
use PDF::Style::Viewport;
use CSS::Declarations;
use CSS::Declarations::Units :pt, :ops;

my $pdf = PDF::Lite.new;
my $gfx = $pdf.add-page.gfx;
my $vp = PDF::Style::Viewport.new: :$gfx, :style("background-color: blue; opacity: 0.2;");

my $css = CSS::Declarations.new: :style("font-family:Helvetica; width:250pt; height:80pt; border: 1pt dashed green; padding: 2pt");

my $text = q:to"--ENOUGH!!--".lines.join: ' ';
    Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt
    ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco.
    --ENOUGH!!--

# manual positioning
$css.bottom = 10pt;
$css.left = 20pt;
# create a styled text block
my $text-elem = $vp.element( :$text, :$css );
# display it on the page
$gfx.do( .xobject, .bottom, .left) with $text-elem;
```

Elements are positioned and sized via CSS properties `top`, `right, `bottom`, `left`, `width` and `height`.

The `render` method places an element directly on a parent page, xobject or pattern, positioning it at the element's `top`, `left` coordinates.

```
use v6;
use PDF::Lite;
use PDF::Style::Viewport;
use PDF::Style::Element;
use CSS::Declarations;
use CSS::Declarations::Units :pt, :ops;

my $pdf = PDF::Lite.new;
my $vp = PDF::Style::Viewport.new: :width(420pt), :height(595pt), :style("background-color: blue; opacity: 0.2;");
my $page = $vp.add-page($pdf);

my $css = CSS::Declarations.new: :style("font-family:Helvetica; width:250pt; height:80pt; top:20pt; left:20pt; border: 1pt dashed green; padding: 2pt");

my $text = q:to"--ENOUGH!!--".lines.join: ' ';
    Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt
    ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco.
    --ENOUGH!!--

my PDF::Style::Element $text-box = $vp.element( :$text, :$css );
$text-box.render($page);

# position an image below the text block
# make some styling adjustments
$css.border-color = 'red';
$css.top ➕= ($text-box.height('padding') + 5)pt;
$css.delete('height');

my Str $image = "t/images/snoopy-happy-dance.jpg";
$vp.element(:$image, :$css).render($page);

$pdf.save-as: "t/example.pdf";
```

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

- basic image rendering and placement (PNG, GIF and JPEG)
- support for a modest subset of available css 2.1 properties
