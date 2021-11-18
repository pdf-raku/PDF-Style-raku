use PDF::Style::Basic;
use CSS::Properties;
use Test;
use PDF::Class;
use PDF::Content;
plan 12;

my CSS::Properties() $css = "font-family: Helvetica; font-size:13pt; white-space: pre; font-style:italic; text-indent:10pt; color:blue; border: 1pt solid red; background-image: url(t/images/snoopy-happy-dance.jpg)";

my PDF::Style::Basic $styler .= new: :$css, :width(120), :height(185);
is $styler.width, 120;
is $styler.height, 185;

my PDF::Class $pdf .= new;
$styler.graphics: $pdf.add-page.gfx, -> $gfx {
    $gfx.transform: :translate(40, 350);
    lives-ok {$styler.style-box($gfx);}
    my %style = $styler.text-box-options;
    is %style<align>, "left";
    is %style<baseline>, "top";
    is %style<font-size>, 13.0;
    isa-ok %style<font>, "PDF::Font::Loader::FontObj";
    is %style<indent>, 10;
    isa-ok %style<kern>, True;
    is-deeply %style<leading>, 1.2;
    is %style<valign>, "top";
    is-deeply %style<verbatum>, True;
    $gfx.say: q:to"END", :width(120), :position[0, 185], |%style;
        Lorem ipsum dolor sit amet, consectetur
        adipiscing elit, sed do eiusmod tempor incididunt
        ut labore et dolore magna aliqua. Ut enim ad minim
        veniam, quis nostrud exercitation ullamco.
        END
}

$pdf.save-as: "t/style-box.pdf";
