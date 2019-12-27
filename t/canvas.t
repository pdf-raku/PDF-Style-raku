use v6;
use Test;
plan 2;

use PDF::Style::Body;
use CSS::Properties;
use CSS::Units :pt, :ops;
use PDF::Lite;
my $canvas-class;
unless try {
    $canvas-class = (require HTML::Canvas);
    require HTML::Canvas::To::PDF; True} {
    skip-rest 'HTML::Canvas[::To::PDF] required to run canvas tests';
    exit;
}
# also dump to HTML, for comparision

my PDF::Style::Body $body .= new;
my CSS::Properties $css .= new: :style("width:250pt; height:80pt; position:absolute; top:20pt; left:20pt; border: 1px solid rgba(0,0,128,.5); background-color: rgba(0,255,0,.1);");
my @Html = '<html>', $body.html-start;

my PDF::Lite $pdf .= new;
my $page = $body.decorate: $pdf.add-page;
$page.gfx.comment = True;
my $n;

sub test($body, $css, $properties = {}, :$canvas!, Bool :$feed = True) {
    $css.set-properties(|$properties);

    my $elem = $body.element( :$canvas, :$css );

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

do {
    my $canvas = $canvas-class.new;
    $canvas.context: -> \ctx {
        ctx.beginPath();
        ctx.arc(95, 50, 40, 0, 2 * pi);
        ctx.stroke();
        ctx.strokeRect(10, 30, 50, 25);
        ctx.fillText("Hello World", 10, 50);
    }
    test($body, $css, :$canvas, );
}

do {
    my $canvas = $canvas-class.new;
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
                ctx.fillText("{++$n}", x, y + 12);
            }
        }
    }
    test($body, $css, :$canvas, { :opacity(.5) });
}

lives-ok {$pdf.save-as: "t/canvas.pdf"};

@Html.append: $body.html-end, '</html>', '';
"t/canvas.html".IO.spurt: @Html.join: "\n";

done-testing;
