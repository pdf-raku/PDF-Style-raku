use v6;
use Test;
plan 1;

use PDF::Style::Body;
use PDF::Style::Element;
use CSS::Properties;
use CSS::Units :pt, :px, :in, :mm, :ops;
use PDF::Class;

# also dump to HTML, for comparision

my CSS::Properties() $css = "font-family:Helvetica; width:250pt; height:80pt; position:absolute; top:20pt; left:20pt";
my PDF::Style::Body $body .= new;
my @Html = '<html>', $body.html-start;

my PDF::Class $pdf .= new;
my $page = $body.decorate: $pdf.add-page;
$page.gfx.comment = True;
my $n;

sub test($body, $css, $settings = {}, Bool :$feed = True) {
    $css."{.key}"() = .value
        for $settings.pairs;

    my $text = $css.write;
    warn {:$text}.perl;
    my $elem = $body.element( :$text, :$css );
    @Html.push: $elem.html;
    .render($page.gfx, .left, .bottom) with $elem;

    if ($feed) {
        if ++$n %% 2 {
            $css.top +css= 100pt;
            $css.left = 20pt;
        }
        else {
            $css.left +css= 270pt;
        }
    }
}

for [
      { :border-width(2px), :border-style<solid>, :border-color<red> },
      # equivalent thickness in different units
      { :border-top-width(3px), :border-right-width(0.03125in), :border-bottom-width(0.7937mm), :border-left-width(2.25pt), :border-style<solid>, :border-color<red> },
      { :border-width<thick>, :border-style<dashed>, :border-color<green> },
      { :border-width<thin>, :border-style<dashed>, :border-color<purple> },
      { :border-width<medium>, :border-style<dotted solid double dashed>, :border-color<blue> },
      { :border-width<5pt>, :border-style<dotted>, :border-color<rgba(100%,0%,0%,.3)> },
      { :border-width<3pt>, :border-style<dashed>, :border-color<purple> },
      { :border-width<5pt>, :border-style<dotted>, :border-top-color<blue>, :border-left-color<green>, :border-bottom-color<yellow>, :border-right-color<red> },
      { :border-width<medium>, :border-style<dotted>, :border-color<hsl(120,100%,50%)> },
      { :padding<5pt>, :padding<2%>},
      ] {

    test($body, $css, $_);
}

$css.delete('top');

# do one padded block positioned from the bottom

$css.bottom = $css.height +css 30pt;
$css.right = ((0pt -css $css.left) -css $css.width) +css ($body.width)pt;
$css.delete('left');
test($body, $css, :!feed);

lives-ok {$pdf.save-as: "t/border.pdf"};

@Html.append: $body.html-end, '</html>', '';
"t/border.html".IO.spurt: @Html.join: "\n";

done-testing;
