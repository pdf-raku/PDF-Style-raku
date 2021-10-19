use v6;
use Test;
plan 1;
use PDF::Content::Tag :Tags;
use PDF::Tags;
use PDF::Tags::Elem;
use PDF::Style::Body;
use PDF::Style::Element;
use CSS::TagSet::TaggedPDF;
if (try require ::('PDF::Class')) === Nil {
    skip-rest 'PDF::Class required for tagged PDF tests';
    exit 0;
}

my $pdf = ::('PDF::Class').new;
my PDF::Style::Body $body .= new;
my $page = $body.decorate: $pdf.add-page;
my CSS::TagSet::TaggedPDF $styler .= new;
my PDF::Tags $tags .= create: :$pdf, :$styler;
my PDF::Tags::Elem $doc = $tags.Document;
my PDF::Tags::Elem $header = $doc.Header1;

$header.mark: $page.gfx, {
    my $css = $header.style;
    my $elem = $body.element: :text("Header text"), :$css;
    .render($page.gfx, 10, 750) with $elem;
}

# todo
# $header.style($gfx, "Header text");

lives-ok {$pdf.save-as: "t/tagged.pdf"};
