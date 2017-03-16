use v6;
use Test;
use PDF::Style::Viewport;
use CSS::Declarations;
use PDF::Lite;

my $bg-image = PDF::Content::Image.open("t/images/semitransparent.gif");
my $css = CSS::Declarations.new: :style("size: a5; margin-left: .5cm; background-image: url($bg-image); background-color: blue; opacity: .3; border: 1px solid red");
warn ~$css;

my $vp = PDF::Style::Viewport.new: :$css;
is $vp.width, 420, 'size - standard';
is $vp.height, 595, 'size - standard';

my $pdf = PDF::Lite.new;
$vp.add-page($pdf);
$pdf.save-as: "t/viewport.pdf";

my $vp2 = PDF::Style::Viewport.new: :style("size: 200pt 300pt");
is $vp2.width, 200, 'size - width + height';
is $vp2.height, 300, 'size - width + height';

$vp2 = PDF::Style::Viewport.new: :style("size: 300px");
is $vp2.width, 300,'size - width only';
is $vp2.height, 300, 'size - width only';

$vp2 = PDF::Style::Viewport.new: :style("size: a5 landscape");
is $vp2.width, 595,'size - width only';
is $vp2.height, 420, 'size - width only';

done-testing;
