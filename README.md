# PDF-Style-raku

## Synopsis
```
use PDF::Style;
use CSS::Properties;
use PDF::Class;
use PDF::Content;

my CSS::Properties() $css = "font-family: Helvetica; white-space: pre; font-weight:bold; text-indent:10pt; color:blue; opacity:.9; border: 1pt solid red; background-image: url(t/images/snoopy-happy-dance.jpg)";

my $width = 120;
my $height = 185;
my PDF::Style $styler .= new: :$css, :$width, :$height;

my PDF::Class $pdf .= new;
$styler.graphics: $pdf.add-page.gfx, -> $gfx {
    say .FillAlpha; # 0.9
    $gfx.transform: :translate(40, 350);
    # create a box using `border` properties
    $styler.style-box($gfx);
    my %text-style = $styler.text-box-options;
    $gfx.say: q:to"END", :$width, :position[0, $height], |%text-style;
        Lorem ipsum dolor sit amet, consectetur
        adipiscing elit, sed do eiusmod tempor incididunt
        ut labore et dolore magna aliqua. Ut enim ad minim
        veniam, quis nostrud exercitation ullamco.
        END
}

$pdf.save-as: "/tmp/styled.pdf";
```
