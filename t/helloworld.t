use v6;
use Test;
use PDF::Compose;
plan 1;
skip_rest 'nyi';exit;
my $pdf = PDF::Compose.new;
$pdf.default.page-size('A4');
$pdf.default.units('mm');
my $font-family = 'Times-Roman';
my $page = $pdf.page(1);

# note the CSS-like box model. applicable to text, images and other graphics
my $pos = $page.text('Hello World !', :style{ :$font-family, :top(10), :left(25), :width(20), :border(2), :align<center> } );

$pdf.save-as('examples/helloworld.pdf');
