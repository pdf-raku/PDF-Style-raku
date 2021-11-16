use PDF::Style;
use CSS::Properties;
use Test;
use PDF::Class;
use PDF::Content;
plan 3;

my CSS::Properties() $css = "font-family: Helvetica; border: 1pt solid red; background-image: url(t/images/snoopy-happy-dance.jpg)";

my PDF::Style $styler .= new: :$css, :width(120), :height(180), :base-url<t/>;
is $styler.width, 120;
is $styler.height, 180;

my PDF::Class $pdf .= new;
$pdf.add-page.graphics: -> $gfx {
    $gfx.transform: :translate(40, 350);
    lives-ok {$styler.style-box($gfx);}
};

$pdf.save-as: "t/style-box.pdf";