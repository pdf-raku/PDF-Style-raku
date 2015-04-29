use v6;
use Test;
use PDF::Compose;
my $pdf = PDF::Compose.new;

isa_ok $pdf, PDF::Compose, 'PDF::Compose.new';
my $page = $pdf.page(1);
isa_ok $page, ::('PDF::Compose::Page'), 'got first page';

my $helvetica;
lives_ok { $helvetica = $page.core-font('Helvetica'); }, 'core font load - lives';
isa_ok $helvetica, ::('Font::Metrics::Helvetica'), 'core font';
is $helvetica.FontName, 'Helvetica', 'font name';
is $helvetica.Weight, 'Medium', 'font weight';

my $tr-bold-italic;
lives_ok { $tr-bold-italic = $page.core-font('Times-Roman', :font-weight<bold>, :font-style<italic>); }, 'core font load - lives';
isa_ok $tr-bold-italic, ::('Font::Metrics::TimesBoldItalic'), 'core font';
is $tr-bold-italic.FontName, 'Times-BoldItalic', 'font name';
is $tr-bold-italic.Weight, 'Bold', 'font weight';
isnt $tr-bold-italic.ItalicAngle, '0', 'italic angle';

my $font-family = 'Helvetica';
my $font-weight = 'bold';

my $css-box = $page.text( 'Hello World', :style{ :$font-family, :$font-weight }, :dry );

done;
