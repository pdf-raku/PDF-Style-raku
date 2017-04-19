use v6;
use Test;
plan 11;

use PDF::Style::Viewport;
use PDF::Style::Element;
use PDF::Lite;
use CSS::Declarations;
use CSS::Declarations::Units :pt, :ops;

# also dump to HTML, for comparision

my $css = CSS::Declarations.new: :style("font-family:Helvetica; height:60pt; position:absolute; top:10pt; left:10pt; right:10pt; border:1pt solid red");
my $vp = PDF::Style::Viewport.new;

my $pdf = PDF::Lite.new;
my $page = $vp.add-page($pdf);
$page.gfx.comment-ops = True;
my @html = '<html>', '<body>', $vp.html-start;
my $n;

constant %Width = %('_' => Mu, '-' => 200pt, '=' => 250pt, '+' => 300pt);

my %seen;

for [ '_=_' => '=',
      '-_+' => '+',
      '+=-' => '+',
      '-+=' => '=',
      '_+=' => '=',
      '+=_' => '+',
      '_=+' => '=',
      '+_=' => '+',
      '-__' => 'long',
      '___' => 'long',
    ] {
    warn "duplicate test: {.key}" if %seen{.key}++;
    my ($min-width, $width, $max-width) = .key.comb.map: { %Width{$_} };
    my $test-width = .value;

    $css.delete($_) for <width min-width max-width>;
    $css.min-width = $_ with $min-width;
    $css.width = $_ with $width;
    $css.max-width = $_ with $max-width;

    my $style = $css.write;
    my $text = (++$n,.value, ':', .key, $style).join: ' ';
    my $elem = $vp.element( :$text, :$css );
    @html.push: $elem.html;
    $elem.render($page);

    my $elem-width = $elem.right - $elem.left;
    my $expected-width = $test-width eq 'long'
        ?? $vp.width - $css.left - $css.right - $css.border-left-width - $css.border-right-width
        !! %Width{$test-width};

    is-approx $elem-width, $expected-width, 'box width';

##    if ++$n %% 2 {
        $css.top ➕= 75pt;
##        $css.left = 20pt;
##    }
##    else {
##        $css.left ➕= 270pt;
##    }
}

lives-ok {$pdf.save-as: "t/widths.pdf"};

@html.append: $vp.html-end, '</body>', '</html>', '';
"t/widths.html".IO.spurt: @html.join: "\n";

done-testing;
