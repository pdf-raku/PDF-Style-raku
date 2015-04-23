use v6;
use Test;
use PDF::Compose;
use CSS::Grammar::CSS3;
use HTML::Parser::XML;

plan 1;

my $html = 't/html/simple-text.html'.IO.slurp;
my $parser = HTML::Parser::XML.new;
diag :$html.perl;
$parser.parse($html);
warn "parsed...";
my $xmldoc = $parser.xmldoc; # XML::Document
warn "progressing...";
# nothing useful yet...";

note $xmldoc;

ok 'skeleton';
