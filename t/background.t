use v6;
use Test;
use PDF::Style::Viewport;
use PDF::Style::Element;
use CSS::Declarations;
use CSS::Declarations::Units :pt, :ops;
use PDF::Lite;

# also dump to HTML, for comparision

my PDF::Style::Viewport $vp .= new;
my CSS::Declarations $css .= new: :style("font-family:Helvetica; height:80pt; position:absolute; top:20pt; left:20pt; border: 5px solid rgba(0,128,0,.2)");
my @Html = '<html>', '<body>', $vp.html-start;

my PDF::Lite $pdf .= new;
my $page = $vp.add-page($pdf);
$page.gfx.comment-ops = True;
my $n;

sub test($vp, $base-css, $settings = {}, Bool :$feed = True) {
    my $css = $base-css.clone(|$settings);
    $css."{.key}"() = .value
        for $settings.pairs;

    my $text = $css.write;
    warn {:$text}.perl;
    my $elem = $vp.element( :$text, :$css );
    @Html.push: $elem.html;
    $elem.render($page);

    if ++$n %% 2 {
        $base-css.top ➕= 100pt;
        $base-css.left = 20pt;
    }
    else {
        $base-css.left ➕= 270pt;
    }
}

for [ { :background-color<rgba(255,0,0,.2)>, :width<250pt> },
      { :background-color<rgba(255,0,0,.2)>, :border-bottom-style<dashed>, :width<250pt>},
      { :background-color<rgba(255,0,0,.2)>, :left<0pt>, :border-width<1pt>, },
      ] {

    test($vp, $css, $_);
}

lives-ok {$pdf.save-as: "t/background.pdf"};

@Html.append: $vp.html-end, '</body>', '</html>', '';
"t/background.html".IO.spurt: @Html.join: "\n";

done-testing;
