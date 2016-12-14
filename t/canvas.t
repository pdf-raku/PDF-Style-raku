use v6;
use Test;
plan 2;

use PDF::Style::Viewport;
use PDF::Style::Box;
use PDF::Style::Font;
use CSS::Declarations;
use CSS::Declarations::Units;
use PDF::Content::PDF;
use HTML::Canvas;
use HTML::Canvas::To::PDF;

# also dump to HTML, for comparision

my $vp = PDF::Style::Viewport.new;
my $css = CSS::Declarations.new: :style("width:250pt; height:80pt; position:absolute; top:20pt; left:20pt; border: 1px solid rgba(0,0,128,.5); background-color: rgba(0,255,0,.1);");
my @Html = '<html>', '<body>', $vp.html-start;

my $pdf = PDF::Content::PDF.new;
my $page = $vp.add-page($pdf);
$page.gfx.comment-ops = True;
my $n;

sub test($vp, $css, $properties = {}, :$canvas!, Bool :$feed = True) {
    $css.set-properties(|$properties);

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

do {
    my HTML::Canvas $canvas .= new;
    $canvas.context: -> \ctx {
        ctx.beginPath();
        ctx.arc(95, 50, 40, 0, 2 * pi);
        ctx.stroke();
        ctx.strokeRect(10, 30, 50, 25);
        ctx.fillText("Hello World", 10, 50);
    }
    test($vp, $css, :$canvas, );
}

do {
    my HTML::Canvas $canvas .= new;
    my $n;
    $canvas.context: -> \ctx {
        ctx.fillStyle = 'red';
        ctx.strokeStyle = 'green';
    }
    $canvas.context: -> \ctx {
        is ctx.strokeStyle, 'green', 'strokeStyle';
        for 1, 239 -> \x {
            for 1, 64 -> \y {
                ctx.strokeRect(x, y, 10, 15);
                ctx.fillText("{++$n}", x + 2, y + 10);
            }
        }
    }
    test($vp, $css, :$canvas, { :opacity(.5) });
}

lives-ok {$pdf.save-as: "t/canvas.pdf"};

@Html.append: $vp.html-end, '</body>', '</html>', '';
"t/canvas.html".IO.spurt: @Html.join: "\n";

done-testing;
