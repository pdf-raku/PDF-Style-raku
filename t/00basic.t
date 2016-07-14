use v6;
use Test;
use PDF::Style::Viewport;
use CSS::Declarations;
use CSS::Declarations::Units;
use PDF::Content::Doc;

my $style = "font-family: Helvetica; font-weight: bold; width: 300px; font-kerning: normal; position:absolute; left: 20px; top: 30px;";
my $css = CSS::Declarations.new( :$style );
my $vp = PDF::Style::Viewport.new;

my $pdf = PDF::Content::Doc.new;
my $page = $pdf.add-page;
my $gfx = $page.gfx;

for <left center right justify> -> $alignment {
    my $header = [~] '*** ALIGN:', $alignment, ' ***', "\n";
    my $body = q:to"--ENOUGH!!--".lines.join: ' ';
        Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt
        ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco
        laboris nisi ut aliquip ex ea commodo consequat.
        --ENOUGH!!--

    note "% **** $alignment *** ";
    $css.text-align = $alignment;    
    for $header, $body -> $text {
        my $text-block = $vp.text( $text, :$css );
        $gfx.print($text-block);
    }
}

note $gfx.content;

done-testing;
