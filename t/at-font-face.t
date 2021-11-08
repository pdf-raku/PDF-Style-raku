use v6;
use Test;
plan 2;

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
$Page.gfx.comment = True;
my @Html = '<html>', $body.html-start;

my $elem = $body.element( :text("Mono Text"), :$css);
@Html.push: $elem.html;
$elem.render: $Page.gfx;
my PDF::Font::Loader::FontObj $font-obj = $body.box.font.font-obj;
is $font-obj.font-name, "FreeMono";

lives-ok {$pdf.save-as: "t/at-font-face.pdf"};

@Html.append: $body.html-end, '</html>', '';
"t/at-font-face.html".IO.spurt: @Html.join: "\n";

done-testing;
