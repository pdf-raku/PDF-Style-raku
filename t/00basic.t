use v6;
use Test;
use PDF::Compose;
my $pdf = PDF::Compose.new;

isa_ok $pdf, PDF::Compose, 'PDF::Compose.new';
my $page = $pdf.page(1);
isa_ok $page, ::('PDF::Compose::Page'), 'got first page';

my $helvetica;
lives_ok { $helvetica = $pdf.core-font('Helvetica'); }, 'core font load - lives';
isa_ok $helvetica, ::('Font::Metrics::Helvetica'), 'core font';
is $helvetica.FontName, 'Helvetica', 'font name';
is $helvetica.Weight, 'Medium', 'font weight';

my $tr-bold-italic;
lives_ok { $tr-bold-italic = $pdf.core-font('Times-Roman', :bold, :italic); }, 'core font load - lives';
isa_ok $tr-bold-italic, ::('Font::Metrics::TimesBoldItalic'), 'core font';
is $tr-bold-italic.FontName, 'Times-BoldItalic', 'font name';
is $tr-bold-italic.Weight, 'Bold', 'font weight';
isnt $tr-bold-italic.ItalicAngle, '0', 'italic angle';

done;
