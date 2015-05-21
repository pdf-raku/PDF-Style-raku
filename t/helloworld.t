use v6;
use Test;
use PDF::Compose;
use PDF::Writer;
plan 1;
##skip_rest 'nyi';exit;
my $pdf = PDF::Compose.new;
##$pdf.default.page-size('A4');
##$pdf.default.units('mm');
my $font-family = 'Times-Roman';
my $page = $pdf.page(1);

# note the CSS-like box model. applicable to text, images and other graphics
my $block = $page.text('Hello World !', :style{ :$font-family, :top(10), :left(25), :width(45), :border(2), :text-align<center>, :font-kerning<normal> } );
my $content = $block.content;
warn PDF::Writer.write( :$content );

pass;

##$pdf.save-as('examples/helloworld.pdf');
