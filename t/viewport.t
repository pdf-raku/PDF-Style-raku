use v6;
use Test;
use PDF::Style::Viewport;
use CSS::Declarations;
use PDF::Lite;

my $bg-image = PDF::Content::Image.open("t/images/semitransparent.gif");
my $css = CSS::Declarations.new: :style("size: a5; margin-left:3pt; background-image: url($bg-image); background-color: blue; opacity: .3; border: 1pt solid red");

my $vp = PDF::Style::Viewport.new: :$css;
constant LeftMargin = 3;
constant Borders = 2; # 1px each side
constant DefaultBorders = 4; # 'medium' := 2px each side

is $vp.width, 420 - LeftMargin - Borders, 'width - standard';
is $vp.height, 595 - Borders, 'height - standard';
is $vp.width('margin'), 420, 'margin width - standard';
is $vp.height('margin'), 595, 'margin height - standard';
my $pdf = PDF::Lite.new;
$vp.add-page($pdf);
$pdf.save-as: "t/viewport.pdf";

my $vp2 = PDF::Style::Viewport.new: :style("size: 200pt 300pt");
is $vp2.width, 200 - DefaultBorders, 'width - width + height';
is $vp2.height, 300 - DefaultBorders, 'height - width + height';
is $vp2.width('margin'), 200, 'margin width - width + height';
is $vp2.height('margin'), 300, 'margin height - width + height';

$vp2 = PDF::Style::Viewport.new: :style("size: 300px");
is $vp2.width('margin'), 300,'margin width - width only';
is $vp2.height('margin'), 300, 'margin height - width only';

$vp2 = PDF::Style::Viewport.new: :style("size: a5 landscape");
is $vp2.width('margin'), 595,'margin width - width only';
is $vp2.height('margin'), 420, 'margin height - width only';

done-testing;
