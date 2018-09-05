use v6;
use Test;
plan 1;

use PDF::Style::Viewport;
use PDF::Style::Element;
use CSS::Properties;
use CSS::Properties::Units :pt, :px, :ops;
use PDF::Lite;

# also dump to HTML, for comparision

my CSS::Properties $css .= new: :style("font-family:Helvetica; width:250pt; height:80pt; position:absolute; top:20pt; left:20pt");
my PDF::Style::Viewport $vp .= new;
my @Html = '<html>', '<body>', $vp.html-start;

my PDF::Lite $pdf .= new;
my $page = $vp.decorate: $pdf.add-page;
$page.gfx.comment-ops = True;
my $n;

sub test($vp, $css, $settings = {}, Bool :$feed = True) {
    $css."{.key}"() = .value
        for $settings.pairs;

    my $text = $css.write;
    warn {:$text}.perl;
    my $elem = $vp.element( :$text, :$css );
    @Html.push: $elem.html;
    $page.gfx.do(.xobject, .left, .bottom) with $elem;

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

for [ { :border-width(2px), :border-style<solid>, :border-color<red> },
      { :border-width<thick>, :border-style<dashed>, :border-color<green> },
      { :border-width<thin>, :border-style<dashed>, :border-color<purple> },
      { :border-width<medium>, :border-style<dotted solid double dashed>, :border-color<blue> },
      { :border-width<5pt>, :border-style<dotted>, :border-color<rgba(100%,0%,0%,.2)> },
      { :border-width<3%>, :border-style<dashed>, :border-color<purple> },
      { :border-width<5pt>, :border-style<dotted>, :border-top-color<blue>, :border-left-color<green>, :border-bottom-color<yellow>, :border-right-color<red> },
      { :border-width<medium>, :border-style<dotted>, :border-color<hsl(120,100%,50%)> },
      { :padding(5pt), },
      ] {

    test($vp, $css, $_);
}

$css.delete('top');

# do one padded block positioned from the bottom

$css.bottom = $css.height +css 30pt;
$css.right = ((0pt -css $css.left) -css $css.width) +css ($vp.width)pt;
$css.delete('left');
test($vp, $css, :!feed);

lives-ok {$pdf.save-as: "t/border.pdf"};

@Html.append: $vp.html-end, '</body>', '</html>', '';
"t/border.html".IO.spurt: @Html.join: "\n";

done-testing;
