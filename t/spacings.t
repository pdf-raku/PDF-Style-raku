use v6;
use Test;
use PDF::Style::Viewport;
use PDF::Style::Element;
use CSS::Declarations;
use CSS::Declarations::Units :pt, :ops;
use PDF::Lite;

# also dump to HTML, for comparision

my $css = CSS::Declarations.new: :style("font-family:Helvetica; width:250pt; height:80pt; position:absolute; top:20pt; left:20pt; border: 1px solid green");
my $vp = PDF::Style::Viewport.new;
my @Html = '<html>', '<body>', $vp.html-start;

my $pdf = PDF::Lite.new;
my $page = $vp.add-page($pdf);
$page.gfx.comment-ops = True;
my $n;

sub test($vp, $base-css, $settings = {}, Bool :$feed = True) {
    my $css = $base-css.clone: |$settings;
    my $text = $css.write;
    warn {:$text}.perl;
    my $elem = $vp.element( :$text, :$css );
    @Html.push: $elem.html;
    $elem.render($page);

    if ($feed) {
        if ++$n %% 2 {
            $base-css.top ➕= 100pt;
            $base-css.left = 20pt;
        }
        else {
            $base-css.left ➕= 270pt;
        }
    }
}

for [ { :line-height<9pt> },
      { :line-height<15pt> },
      { :line-height<85%> },
      { :line-height<110%> },
      { :line-height(.85) },
      { :line-height(1.1) },
      { :letter-spacing<1pt> },
      { :letter-spacing<-1pt> },
      { :word-spacing<5pt> },
      { :word-spacing<15pt> },
      ] {

    test($vp, $css, $_);
}

$css.delete('top');

# do one padded block positioned from the bottom

$css.bottom = $css.height ➕ 30pt;
$css.right = ($vp.width)pt ➖ $css.left ➖ $css.width;
$css.delete('left');
test($vp, $css, :!feed);

lives-ok {$pdf.save-as: "t/spacings.pdf"};

@Html.append: $vp.html-end, '</body>', '</html>', '';
"t/spacings.html".IO.spurt: @Html.join: "\n";

done-testing;
