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

done;
