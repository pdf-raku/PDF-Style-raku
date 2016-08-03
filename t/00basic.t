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

    note "% **** align $alignment *** ";
    $css.text-align = :keyw($alignment);
    $css.font-weight = :keyw<bold>;
        
    for $header, $body {
        my Str $style = $css.write;
        my Str $text = $_;
        $text ~= ' ' ~ $style if $css.font-weight eq 'normal';
        my ($text-block, $box) = $vp.text( $text, :$css );
        @html.push: sprintf '<div style="%s">%s</div>', $style, $text;
        $page.graphics: {
            $box.style($_);
            $page.text: {
                my $left = $box.left;
                my $top = $box.top;
                .print($text-block, :position[:$left, :$top]);
            }
        }
        $css.top += 15pt;
        $css.font-weight = :keyw<normal>;
    }
    $css.top += 100pt;
}

$css.delete("text-align");
$css.vertical-align = :keyw<left>;
$css.top = 30pt;
$css.left = 350pt;
$css.width = 220pt;

for <top center bottom> -> $valign {
    my $header = [~] '*** VALIGN:', $valign, ' ***', "\n";
    my $body = q:to"--ENOUGH!!--".lines.join: ' ';
        Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt
        --ENOUGH!!--

    note "% **** valign $valign *** ";
    $css.delete("height");
    $css.font-weight = :keyw<bold>;
    my Str $style = $css.write;
        
    my ($text-block, $box) = $vp.text( $header, :$css );
    @html.push: sprintf '<div style="%s">%s</div>', $style, $header;
    $page.graphics: {
        $box.style($_);
        $page.text: {
            .print($text-block, :position[$box.left, $box.top]);
        }
    }

    $css.top += 15pt;
    $css.font-weight = :keyw<normal>;
    $css.height = 130pt;
    $style = $css.write;
    my $text = $body ~ $style;
    ($text-block, $box) = $vp.text( $text, :$css, :$valign );
    @html.push: sprintf '<div style="%s"><div style="position:relative; top:%dpt">%s</div></div>', $style, $text-block.top-offset, $text;
    $page.graphics: {
        $box.style($_);
        $page.text: {
            my $left = $box.left;
            my $top = $box.top;
            .print($text-block, :position[:$left, :$top]);
        }
    }

    $css.top += 165pt;

}

lives-ok {$pdf.save-as: "t/00basic.pdf"};

@html.append: '</body>', '</html>', '';
"t/00basic.html".IO.spurt: @html.join: "\n";

done-testing;
