use v6;
use Test;
use PDF::Style :pt;
use PDF::Style::Viewport;
use PDF::Style::Box;
use CSS::Declarations;
use CSS::Declarations::Units;
use PDF::Content::PDF;
use HTML::Canvas;

# also dump to HTML, for comparision

my $vp = PDF::Style::Viewport.new;
my $css = CSS::Declarations.new: :style("font-family:Helvetica; width:250pt; height:80pt; position:absolute; top:20pt; left:20pt; border: 5px solid rgba(0,128,0,.2)");
my @Html = '<html>', '<body>', $vp.html-start;

my $pdf = PDF::Content::PDF.new;
my $page = $vp.add-page($pdf);
$page.gfx.comment-ops = True;
my $n;

sub test($vp, $css, $properties = {}, Bool :$feed = True) {
    $css.set-properties(|$properties);

    my HTML::Canvas $canvas .= new;
    $canvas.beginPath();
    $canvas.arc(95, 50, 40, 0, 2 * pi);
    $canvas.stroke();
    $canvas.strokeRect(10, 30, 50, 25);
    $canvas.fillText("Hello World", 10, 50);

    my $box = $vp.box( :$canvas, :$css );

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

test($vp, $css,  { :background-color<rgba(255,0,0,.2)>, :left<0pt>, :border-width<1pt>, :width<593pt>, });

lives-ok {$pdf.save-as: "t/canvas.pdf"};

@Html.append: $vp.html-end, '</body>', '</html>', '';
"t/canvas.html".IO.spurt: @Html.join: "\n";

done-testing;
