use v6;
use Test;
use PDF::Style::Viewport;
use CSS::Declarations;
use CSS::Declarations::Units;
use PDF::Content::PDF;

# also dump to HTML, for comparision

my @html = '<html>', '<body style="position:relative">';

my $style = "font-family: Helvetica; font-weight: bold; width: 300pt; font-kerning: normal; position:absolute; left: 20px; top: 30px; border: 1px solid red";
my $css = CSS::Declarations.new( :$style );
my $vp = PDF::Style::Viewport.new;

my $pdf = PDF::Content::PDF.new;
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
    $css.text-align = :keyw($alignment);    
    for $header, $body -> $text {
        my $text-block = $vp.text( $text, :$css );
        @html.push: sprintf '<div style="%s">%s</div>', $css.write, $text;
        $gfx.print($text-block);
        $css.top += 20px;
    }
    $css.top += 100px;

}

lives-ok {$pdf.save-as: "t/00basic.pdf"};

@html.append: '</body>', '</html>', '';
"t/00basic.html".IO.spurt: @html.join: "\n";

note $gfx.content;

done-testing;
