PDF-Style-p6
============
__Experimental!__

This is an extension module for `PDF::Lite` and `PDF::API6`, etc. It implements some basic CSS styling rules for simple PDF components, such as forms, images, or plain text blocks.

## Supported Properties

Type | Properties
---  | ---
Borders | border-color, border-style ('dotted', 'dashed', 'solid' only),  border-width, padding, margin
Backgrounds | background-color, background-image (url encoded only), background-position, background-repeat
Sizing  | height, max-height, min-height, width, max-width, min-width
Text | font-family, font-style, font-size, font-kerning, font-stretch, font-weight, color, letter-spacing, line-height, text-align vertical-align ('top', 'center', 'bottom' only), word-spacing 
Positioning  | bottom, top, left, right
Viewport | size, (also border and background properties: padding, border, margin, background-color, etc)
Other | opacity

## Simple Styling

```
use v6;
use PDF::Lite;
use PDF::Style;
use CSS::Declarations;
use CSS::Declarations::Units :pt, :ops;

my $pdf = PDF::Lite.new;
my $page = $pdf.add-page;
$page.media-box = 0, 0, 120, 150;

# create and output a styled text-block
my $css = CSS::Declarations.new: :style("font-family:Helvetica; width:250pt; height:80pt; border: 1pt dashed green; padding: 2pt; word-spacing:3pt");

my $text = q:to"--ENOUGH!!--".lines.join: ' ';
    Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt
    ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco.
    --ENOUGH!!--

my $text-elem = PDF::Style.element( :$text, :$css );

# display it on the page
my $bottom = 10pt;
my $left = 20pt;
$page.gfx.do( .xobject, $bottom, $left) with $text-elem;
```

## View-Port Positioning

Elements positions and sizes on a viewport are calculated from CSS properties `top`, `right, `bottom`, `left`, `width` and `height`.

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
my $page = $vp.decorate: $pdf.add-page;

my $css = CSS::Declarations.new: :style("font-family:Helvetica; width:250pt; height:80pt; top:20pt; left:20pt; border: 1pt dashed green; padding: 2pt");

my $text = q:to"--ENOUGH!!--".lines.join: ' ';
    Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt
    ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco.
    --ENOUGH!!--

my PDF::Style::Element $text-box = $vp.element( :$text, :$css );
$text-box.render($page);

# position an image below the text block,
# after some styling adjustments
$css.border-color = 'red';
$css.top ➕= ($text-box.height('padding') + 5)pt;
$css.delete('height');

my Str $image = "t/images/snoopy-happy-dance.jpg";
$vp.element(:$image, :$css).render($page);

$pdf.save-as: "t/example.pdf";
```

## CSS Property todo lists:

Property|Notes|To-do
---|---|---
border-style|'dotted', 'dashed', 'solid'|Other styles.
text-decoration||NYI
text-indent||NYI
text-transform||NYI
vertical-align|'top', 'center', 'bottom' only|Other modes
  
### CSS Property Shortlist
- content
- direction
- display
- font-variant
- empty-cells
- float
- list-style, list-style-image, list-style-position, list-style-type
- outline, outline-width, outline-style, outline-color
- overflow
- unicode-bidi
- table-layout
- visibility
- white-spacing

### Nice to have:

Fonts:
- font-synthesis
- @font-face

Viewport
- @top-left-corner, etc
- page-break-before, page-break-after, page-break-inside

CSS Transforms http://dev.w3.org/csswg/css-transforms/#transform
- transform
- transform-origin

