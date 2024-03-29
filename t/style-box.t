use PDF::Style;
use CSS::Properties;
use Test;
use PDF::Class;
use PDF::Content;
use PDF::Content::Color :&color, :ColorName;
plan 12;

my CSS::Properties() $css = "font-family: Helvetica; font-size:13pt; white-space: pre; font-style:italic; text-indent:10pt; color:blue; border: 1pt solid red; margin:2pt; padding:5pt; background-image: url(t/images/snoopy-happy-dance.jpg)";

my $width = 120;
my $height = 180;

my PDF::Class $pdf .= new;
my PDF::Content $gfx = $pdf.add-page.gfx;
my PDF::Style $box .= new: :$css, :$width, :$height, :$gfx;
is $box.width, $width;
is $box.height, $height;

my $text = q:to"END";
        Lorem ipsum dolor sit amet, consectetur
        adipiscing elit, sed do eiusmod tempor incididunt
        ut labore et dolore magna aliqua. Ut enim ad minim
        veniam, quis nostrud exercitation ullamco.
        END

$box.graphics: -> $gfx {
    $gfx.transform: :translate(40, 350);
    draw-hairline($gfx);
    lives-ok {$box.style-box($gfx);}
    my %style = $box.text-box-options;
    is %style<align>, "left";
    is %style<baseline>, "top";
    is %style<font-size>, 13.0;
    isa-ok %style<font>, "PDF::Font::Loader::FontObj";
    is %style<indent>, 10;
    isa-ok %style<kern>, True;
    is-deeply %style<leading>, 1.2;
    is %style<valign>, "top";
    is-deeply %style<verbatim>, True;
    %style<valign> = 'bottom';
    $gfx.say: $text, :$width, :$height, |%style;
}

$gfx.graphics: {
    $gfx.transform: :translate(40, 140);
    draw-hairline($gfx);
    $box.say($text);
}

$pdf.save-as: "t/style-box.pdf";

sub draw-hairline($gfx) {
    $gfx.Save;
    $gfx.StrokeColor = color Blue;
    $gfx.MoveTo(0, -20);
    $gfx.LineTo(0, +20);
    $gfx.Stroke;
    $gfx.MoveTo(-20, 0);
    $gfx.LineTo(+20, 0);
    $gfx.Stroke;
    $gfx.Restore;
}