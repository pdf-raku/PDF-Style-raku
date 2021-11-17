# PDF-Style-Basic-raku

## Synopisis
```
use PDF::Style::Basic;
use CSS::Properties;
use PDF::Class;
use PDF::Content;

my CSS::Properties() $css = "font-family: Helvetica; white-space: pre; font-weight:bold; text-indent:10pt; color:blue; opacity:.9; border: 1pt solid red; background-image: url(t/images/snoopy-happy-dance.jpg)";

my PDF::Style::Basic $styler .= new: :$css, :width(120), :height(185);
is $styler.width, 120;
is $styler.height, 185;

my PDF::Class $pdf .= new;
$styler.graphics: $pdf.add-page.gfx, -> $gfx {
    say .FillAlpha; # 0.9
    # create a box using `border` properties
    $gfx.transform: :translate(40, 350);
    $styler.style-box($gfx);
    my %text-style = $styler.text-box-options;
    $gfx.say: q:to"END", :width(120), :position[0, 185], |%text-style;
        Lorem ipsum dolor sit amet, consectetur
        adipiscing elit, sed do eiusmod tempor incididunt
        ut labore et dolore magna aliqua. Ut enim ad minim
        veniam, quis nostrud exercitation ullamco.
        END
}

$pdf.save-as: "/tmp/styled.pdf";
```
