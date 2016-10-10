use v6;
use Test;
use PDF::Style :pt;
use PDF::Style::Viewport;
use PDF::Style::Box;
use CSS::Declarations;
use CSS::Declarations::Units;
use PDF::Content::PDF;

# also dump to HTML, for comparision

my $vp = PDF::Style::Viewport.new;
my $css = CSS::Declarations.new: :style("font-family:Helvetica; width:200pt; height:250pt; position:absolute; top:20pt; left:20pt; border: 5px solid rgba(0,128,0,.2)");
my @Html = '<html>', '<body>', $vp.html-start;

my $pdf = PDF::Content::PDF.new;
my $page = $vp.add-page($pdf);
$page.gfx.comment-ops = True;
my $n;

sub test($vp, $css, $settings = {}, Bool :$feed = True, |c) {
    $css."{.key}"() = .value
        for $settings.pairs;

    my $box = $vp.box( :$css, |c );
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

my $image = "t/images/snoopy-happy-dance.jpg";

for [ { :background-color<rgba(255,0,0,.2)> },
      { :background-color<rgba(255,0,0,.2)>, :border-bottom-style<dashed>, :width<160pt> },
      ] {

    test($vp, $css, $_, :$image);
}

lives-ok {$pdf.save-as: "t/images.pdf"};

@Html.append: $vp.html-end, '</body>', '</html>', '';
"t/images.html".IO.spurt: @Html.join: "\n";

done-testing;
