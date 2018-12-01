use v6;
use Test;
use PDF::Style::Body;
use PDF::Style::Element;
use CSS::Properties;
use CSS::Properties::Units :pt, :ops;
use PDF::Lite;

# also dump to HTML, for comparision

my PDF::Style::Body $body .= new;
my CSS::Properties $css .= new: :style("font-family:Helvetica; height:80pt; position:absolute; top:20pt; left:20pt; border: 5px solid rgba(0,128,0,.2)");
my @Html = '<html>', $body.html-start;

my PDF::Lite $pdf .= new;
my $page = $body.decorate: $pdf.add-page;
$page.gfx.comment-ops = True;
my $n;

sub test($body, $base-css, $settings = {}, Bool :$feed = True) {
    my $css = $base-css.clone(|$settings);
    $css."{.key}"() = .value
        for $settings.pairs;

    my $text = $css.write;
    warn {:$text}.perl;
    my $elem = $body.element( :$text, :$css );
    @Html.push: $elem.html;
    $page.gfx.do(.xobject, .left, .bottom) with $elem;

    if ++$n %% 2 {
        $base-css.top +css= 100pt;
        $base-css.left = 20pt;
    }
    else {
        $base-css.left +css= 270pt;
    }
}

for [ { :background-color<rgba(255,0,0,.2)>, :width<250pt> },
      { :background-color<rgba(255,0,0,.2)>, :border-bottom-style<dashed>, :width<250pt>},
      { :background-color<rgba(255,0,0,.2)>, :left<0pt>, :border-width<1pt>, },
      ] {

    test($body, $css, $_);
}

lives-ok {$pdf.save-as: "t/background.pdf"};

@Html.append: $body.html-end, '</html>', '';
"t/background.html".IO.spurt: @Html.join: "\n";

done-testing;
