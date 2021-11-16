use PDF::Style;
use CSS::Properties;
use Test;
use PDF::Class;
use PDF::Content;
plan 12;

my CSS::Properties() $css = "font-family: Helvetica; white-space: pre; font-weight:bold; text-indent:2pt; border: 1pt solid red; background-image: url(t/images/snoopy-happy-dance.jpg)";

my PDF::Style $styler .= new: :$css, :width(120), :height(180);
is $styler.width, 120;
is $styler.height, 180;

my PDF::Class $pdf .= new;
$pdf.add-page.graphics: -> $gfx {
    $gfx.transform: :translate(40, 350);
    lives-ok {$styler.style-box($gfx);}
    my %options = $styler.text-box-options;
    is %options<align>, "left";
    is %options<baseline>, "top";
    is-deeply %options<font-size>, 12;
    isa-ok %options<font>, "PDF::Font::Loader::FontObj";
    is %options<indent>, 2;
    isa-ok %options<kern>, True;
    is-deeply %options<leading>, 1.2;
    is %options<valign>, "top";
    is-deeply %options<verbatum>, True;
};

$pdf.save-as: "t/style-box.pdf";