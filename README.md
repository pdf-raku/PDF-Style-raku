PDF-Style-raku
============
__Experimental and under construction!__

This is a styling module designed to work with the Raku PDF Tool-chain, including  `PDF::Class` and `PDF::API6`, etc.

It implements some basic CSS styling of PDF components, including pages, forms, images, or text blocks.

## Simple Styling

```
use v6;
use PDF::Class;
use PDF::Style::Element;
use CSS::Properties;
use CSS::Units :pt, :ops;

my PDF::Class $pdf .= new;
my $page = $pdf.add-page;
$page.media-box = 0, 0, 350, 140;

# create and output a styled text-block
my CSS::Properties() $css = "font-family:Helvetica; width:250pt; height:80pt; border:1pt dashed green; padding: 5pt; word-spacing:10pt;";

my $text = q:to"--ENOUGH!!--".lines.join: ' ';
    Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt
    ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco.
    --ENOUGH!!--

$css.bottom = 20pt;
$css.left = 20pt;
my PDF::Style::Element $text-elem .= element: :$text, :$css;

# display it on the page
.render( $page.gfx, .bottom, .left) given $text-elem;
$pdf.save-as: "examples/styled-text.pdf";
```
![example.pdf](examples/.previews/styled-text-001.png)

## Supported Properties

Type | Properties
---  | ---
Borders | border-color, border-style ('dotted', 'dashed', 'solid' only),  border-width, padding, margin
Backgrounds | background-color, background-image (url encoded only), background-position, background-repeat
Sizing  | height, max-height, min-height, width, max-width, min-width
Text | font-family, font-style, font-size, font-kerning, font-stretch, font-weight, color, letter-spacing, line-height, text-align, text-indent, vertical-align ('top', 'center', 'bottom' only), word-spacing 
Positioning  | bottom, top, left, right
Body | size, (also border and background properties: padding, border, margin, background-color, etc)
Other | opacity

## Bodies [PDF::Style::Body]

Elements positions and sizes on a body are calculated from CSS properties `top`, `right, `bottom`, `left`, `width` and `height`.

```
use PDF::Class;
use PDF::Style::Body;
use PDF::Style::Element;
use CSS::Properties;
use CSS::Units :pt, :ops;
use PDF::Content::XObject;

my PDF::Content::XObject $background-image .= open: "t/images/tiny.png";
my CSS::Properties() $css = "background-color: rgb(180,180,250); background-image: url($background-image); opacity: 0.25; width:420pt; height:595pt";
my PDF::Style::Body $body .= new: :$css;

my PDF::Class $pdf .= new;

# Create a page, sized and decorated from the body element
my $page = $body.decorate: $pdf.add-page;

# create and lay up some styled elements
my CSS::Properties() $css = "font-family:Helvetica; width:250pt; height:80pt; top:20pt; left:20pt; border: 1pt solid green; padding: 2pt";

my $text = "Text, styled as $css";

my PDF::Style::Element $text-elem = $body.element( :$text, :$css );

given $text-elem {
    note "text top-left is {.top}pt {.left}pt from page bottom, left corner";
    # output the element on the page.
    .render($page.gfx, .left, .bottom);
}

# now position an image below the text block,
# after some styling adjustments
$css.border-color = 'red';
$css.border-style = 'dashed';
$css.top +css= ($text-elem.height('padding') + 5)pt;
$css.height = Nil;

my Str $image = "t/images/snoopy-happy-dance.jpg";
given $body.element(:$image, :$css) {
    note "image bottom-right is {.bottom}pt {.left}pt from page bottom, left corner";
    .render($page.gfx, .left, .bottom);
}

# position from bottom right
$css .= COERCE: "border:2pt dashed green; bottom:5pt; color:blue; font-family:Helvetica; padding:2pt; right:5pt; text-align:right; width:120pt;";
.render($page.gfx, .left, .bottom)
    given $body.element( :text("Text styled as $css"), :$css );

$pdf.save-as: "examples/styling.pdf";
# also save as HTML

"t/example.html".IO.spurt: $body.html;
```
![example.pdf](t/.previews/styling-001.png)

## Font Management

By default, this module uses `fontconfig` to
load the most appropriate system font for the current CSS font properties (`font-family`, `font-style`, `font-weight, and `font-stretch`).

CSS `@font-face` font descriptors can be used to define a set of fonts to load based on font properties.

```
use PDF::Style::Body;
use PDF::Style::Element;
use CSS::Font::Descriptor;
use CSS::Properties;
use CSS::Units :pt, :ops;
use PDF::Class;
use PDF::Font::Loader::FontObj;

my CSS::Font::Descriptor() @font-face = q:to<END>;
    font-family: "ugly";
    src: url("fonts/FreeMono.ttf");
    END

my CSS::Properties() $css = "font-family:ugly; height:30pt; width:110pt; position:absolute; top:10pt; left:10pt; right:10pt; border:1pt solid red;";
my PDF::Style::Body $body .= new: :@font-face, :base-url<t/>;

my PDF::Class $pdf .= new;
my $Page = $body.decorate: $pdf.add-page;

my $elem = $body.element( :text("Mono Text"), :$css);
$elem.render: $Page.gfx;

$pdf.save-as: "/tmp/at-font-face.pdf";
```

## PDF::Tags Integration

The `:tag` option may be used on the `element()` method to link the element
into the PDF Structure tree.

Futhermore, the `:styler` option may be used on the PDF::Tags root element to inherit styling for the tags, so that the PDF can be both tagged and styled at the
same time.

```
use PDF::Tags;
use PDF::Tags::Elem;
use PDF::Style::Body;
use PDF::Style::Element;
use CSS::TagSet::TaggedPDF;
use CSS::Properties;
use PDF::Class;
use PDF::Page;

my PDF::Class $pdf .= new;
my PDF::Style::Body $body .= new;
my PDF::Page $page = $body.decorate: $pdf.add-page;
my CSS::TagSet::TaggedPDF $styler .= new;
my PDF::Tags $tags .= create: :$pdf, :$styler;
my PDF::Tags::Elem $doc = $tags.Document;

# add tagged/styled header text
my PDF::Tags::Elem $header = $doc.Header1;
my $elem = $body.element: :text("Tagged/Styled PDF Demo"), :tag($header);
note $elem.css; # display:block; font-size:2em; font-weight:bolder; margin-bottom:0.67em; margin-top:0.67em; unicode-bidi:embed;
.render($page.gfx, 10, 750) with $elem;

# add tagged/styled figure image
my PDF::Tags::Elem $figure = $doc.Figure: :Alt("light bulb");
my Str $image = "t/images/snoopy-happy-dance.jpg";
my CSS::Properties() $css = "padding:2px; border:1px dashed red; opacity:0.5";
my $image-elem = $body.element(:$image, :tag($figure), :$css);
.render($page.gfx, 10, 550) with $image-elem;

$pdf.save-as: "t/tag-demo.pdf"
```

## Bugs/Limitations

 - Tags don't yet integrate with CSS Selectors

### CSS Property todo lists:

Property|Notes|To-do
---|---|---
border-style|'dotted', 'dashed', 'solid'|Other styles.
text-decoration||NYI
text-transform||NYI
white-space|normal and pre-wrap|Other modes
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
- text-decoration
- visibility

### Nice to have:

Fonts:
- font-synthesis
- @font-face

Body
- @top-left-corner, etc
- page-break-before, page-break-after, page-break-inside

CSS Transforms http://dev.w3.org/csswg/css-transforms/#transform
- transform
- transform-origin

