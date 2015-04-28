use v6;
use Test;
use PDF::Compose;
# css 2.1 compat - for now
use CSS::Module::CSS21;
use CSS::Module::CSS21::Actions;
use HTML::Parser::XML;

plan 14;

diag "loading html";
my $html = 't/html/basic-p-tag.html'.IO.slurp;
my $parser = HTML::Parser::XML.new;
diag "loaded html";
diag :$html.perl;
diag "parsing...";
$parser.parse($html);
warn "parsed...";
my $xmldoc = $parser.xmldoc; # XML::Document
warn "progressing...";

my $root = $xmldoc.root;
my $body;
my $actions = CSS::Module::CSS21::Actions.new;

if $root.name eq 'html' {
    my @bodies = $root.nodes.grep({.can('name') && .name eq 'body' });
    die "unable to find html body"
        unless @bodies;
    die "html has multiple bodie elements"
        if @bodies > 1;
    $body = @bodies[0];
}
else {
    die "bad root element: $root";
}

for $body.nodes.list {

    when XML::Text {
        todo "XML::Text elems";
        flunk "plain text tests";
    }

    when XML::Element {
        if my $style = .<style> {
            diag "style: $style";
            ok CSS::Module::CSS21.parse($style,:$actions), "style parse";
            my $style-ast = $/.ast;
            ok $style-ast, 'got style ast';
            todo "style attribute processing";
            flunk "style tests";
        }

        given .name {
            when 'div' { todo "div tests"; flunk "div tests" }
            when 'p' { todo "paragraph tests"; flunk "paragpaph tests" }
            when 'span' { todo "span tests"; flunk "span tests" }
            default { diag "unhandled {.name} tag"; }
        }
    }

    when XML::Comment {}

    default { diag "unandled node: {.gist}" }
}

ok 'skeleton';
