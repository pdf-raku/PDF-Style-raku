use v6;
use Test;
use PDF::Style :pt;
use PDF::Style::Viewport;
use PDF::Style::Box;
use CSS::Declarations;
use CSS::Declarations::Units;
use PDF::Content::PDF;

# also dump to HTML, for comparision

my @html = '<html>', '<body style="position:relative">';

my $style = "font-family: Helvetica; width: 300pt; position:absolute; left: 20pt; top: 30pt; border: 1pt solid red";
my $css = CSS::Declarations.new( :$style );
my $vp = PDF::Style::Viewport.new;

my $pdf = PDF::Content::PDF.new;
my $page = $pdf.add-page;
$page.media-box = [0, 0, pt($vp.width), pt($vp.height) ]; 

for <left center right justify> -> $alignment {
    my $header = [~] '*** ALIGN:', $alignment, ' ***', "\n";
    my $body = q:to"--ENOUGH!!--".lines.join: ' ';
        Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt
        ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco.
        --ENOUGH!!--

    note "% **** $alignment *** ";
    $css.text-align = :keyw($alignment);
    my @fw = 'bold', 'normal';    
        
    for $header, $body {
        $css.font-weight = :keyw(@fw.shift);
        my Str $style = $css.write;
        my Str $text = $_;
        $text ~= ' ' ~ $style if $css.font-weight eq 'normal';
        my ($text-block, $box, $left, $top) = $vp.text( $text, :$css );
        @html.push: sprintf '<div style="%s">%s</div>', $style, $text;
        $page.graphics: {
            $box.style($_);
            $page.text: {
                .print($text-block, :position[$left, $top]);
            }
        }
        $css.top += 15pt;
    }
    $css.top += 90pt;

}

lives-ok {$pdf.save-as: "t/00basic.pdf"};

@html.append: '</body>', '</html>', '';
"t/00basic.html".IO.spurt: @html.join: "\n";

done-testing;
