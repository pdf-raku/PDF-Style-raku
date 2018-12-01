use v6;
use Test;
use PDF::Style::Body;
use CSS::Properties;
use PDF::Lite;
use PDF::Content::XObject;

my $bg-image = PDF::Content::XObject.open("t/images/semitransparent.gif");
my CSS::Properties $css .= new: :style("size: a5; margin-left:3pt; background-image: url($bg-image); background-color: blue; opacity: .3; border: 1pt solid red");

my PDF::Style::Body $body .= new: :$css;
my @html = '<html>', $body.html-start;

constant LeftMargin = 3;
constant Borders = 2; # 1px each side
constant DefaultBorders = 4; # 'medium' := 2px each side

is $body.width, 420 - LeftMargin - Borders, 'width - standard';
is $body.height, 595 - Borders, 'height - standard';
is $body.width('margin'), 420, 'margin width';
is $body.height('margin'), 595, 'margin height';
my PDF::Lite $pdf .= new;
my $page = $body.decorate($pdf.add-page);
is $page.width, 420, 'decorated page width';
is $page.height, 595, 'decorated page height';

$pdf.save-as: "t/body.pdf";
@html.append: $body.html-end, '</html>', '';
"t/body.html".IO.spurt: @html.join: "\n";

my PDF::Style::Body $body2 .= new: :style("size: 200pt 300pt");
is $body2.width, 200 - DefaultBorders, 'width - width + height';
is $body2.height, 300 - DefaultBorders, 'height - width + height';
is $body2.width('margin'), 200, 'margin width';
is $body2.height('margin'), 300, 'margin height';

$body2 = PDF::Style::Body.new: :style("size: 300px");
is $body2.width('margin'), 300,'margin width';
is $body2.height('margin'), 300, 'margin height';

my $gfx = $pdf.add-page.gfx;

$body2 = PDF::Style::Body.new: :$gfx, :style("size: a5 landscape");
is $body2.width('margin'), 595,'margin width';
is $body2.height('margin'), 420, 'margin height';

$body2 = PDF::Style::Body.new: :$gfx;
is $body2.width('margin'), $gfx.width,'margin width';
is $body2.height('margin'),$gfx.height, 'margin height';

done-testing;
