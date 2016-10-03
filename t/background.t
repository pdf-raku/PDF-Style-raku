use v6;
use Test;
use PDF::Style :pt;
use PDF::Style::Viewport;
use PDF::Style::Box;
use CSS::Declarations;
use CSS::Declarations::Units;
use PDF::Content::PDF;

# also dump to HTML, for comparision

my $vp = PDF::Style::Viewport.new: style("width:595pt; height:842pt");
my $css = CSS::Declarations.new: :style("font-family:Helvetica; width:250pt; height:80pt; position:absolute; top:20pt; left:20pt; border: 5px solid rgba(0,128,0,.2)");
my @Html = '<html>', sprintf('<body style="{~$vp.css}"');

my $pdf = PDF::Content::PDF.new;
my $page = $pdf.add-page;
$page.gfx.comment-ops = True;
$page.media-box = [0, 0, pt($vp.width), pt($vp.height) ];
my $n;

sub test($vp, $css, $settings = {}, Bool :$feed = True) {
    $css."{.key}"() = .value
        for $settings.pairs;

    my $style = $css.write;
    warn {:$style}.perl;
    my $box = $vp.text-box( $style, :$css );
    @Html.push: $box.html;
    $box.render($page);

    if ($feed) {
        if ++$n %% 2 {
            $css.top += 100pt;
            $css.left = 20pt;
        }
        else {
            $css.left += 270pt;
        }
    }
}

for [ { :background-color<rgba(255,0,0,.2)> },
      { :background-color<rgba(255,0,0,.2)>, :border-bottom-style<dashed>, },
      ] {

    test($vp, $css, $_);
}

lives-ok {$pdf.save-as: "t/background.pdf"};

@Html.append: '</body>', '</html>', '';
"t/background.html".IO.spurt: @Html.join: "\n";

done-testing;
