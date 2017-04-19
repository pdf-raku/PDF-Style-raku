use v6;
use Test;
use PDF::Style::Viewport;
use PDF::Style::Element;
use CSS::Declarations;
use CSS::Declarations::Units :pt, :ops;
use PDF::Lite;

# also dump to HTML, for comparision

my $vp = PDF::Style::Viewport.new;
my $css = CSS::Declarations.new: :style("font-family:Helvetica; width:250pt; height:80pt; position:absolute; top:20pt; left:20pt; border: 5px solid rgba(0,128,0,.2)");
my @Html = '<html>', '<body>', $vp.html-start;

my $pdf = PDF::Lite.new;
my $page = $vp.add-page($pdf);
$page.gfx.comment-ops = True;
my $n;

sub test($vp, $css, $settings = {}, Bool :$feed = True) {
    $css."{.key}"() = .value
        for $settings.pairs;

    my $text = $css.write;
    warn {:$text}.perl;
    my $elem = $vp.element( :$text, :$css );
    @Html.push: $elem.html;
    $elem.render($page);

    if ++$n %% 2 {
        $css.top ➕= 100pt;
        $css.left = 20pt;
    }
    else {
        $css.left ➕= 270pt;
    }
}

for [ { :background-color<rgba(255,0,0,.2)> },
      { :background-color<rgba(255,0,0,.2)>, :border-bottom-style<dashed>, },
      { :background-color<rgba(255,0,0,.2)>, :left<0pt>, :border-width<1pt>, :width<593pt>, },
      ] {

    test($vp, $css, $_);
}

lives-ok {$pdf.save-as: "t/background.pdf"};

@Html.append: $vp.html-end, '</body>', '</html>', '';
"t/background.html".IO.spurt: @Html.join: "\n";

done-testing;
