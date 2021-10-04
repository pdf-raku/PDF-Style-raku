use v6;
use Test;
plan 1;
use PDF::Content::Tag :Tags;
use PDF::Tags;
use PDF::Class;
use PDF::Tags::Elem;
use PDF::Style::Body;
use PDF::Style::Element;
use CSS::TagSet::TaggedPDF;

my PDF::Style::Body $body .= new;
my PDF::Class $pdf .= new;
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
