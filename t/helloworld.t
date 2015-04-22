use PDF::Compose;

my $pdf = PDF::Compose.new;
$pdf.page-size('A4');
$pdf.units('mm');
my $font-family = 'Times-Roman';
my $page = $doc.page(1);

# note the CSS-like box model. applicable to text, images and other graphics
my $pos = $page.text('Hello World !', :$font-family, :top(10), :left(25), :width(20), :border(2), :align<center> ); );

$pdf.save-as('examples/helloworld.pdf');
