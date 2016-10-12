use v6;
use Test;
use PDF::Style :pt;
use PDF::Style::Viewport;
use PDF::Style::Box;
use CSS::Declarations;
use CSS::Declarations::Units;
use PDF::Content::PDF;

# also dump to HTML, for comparision

my $css = CSS::Declarations.new: :style("font-family:Helvetica; height:60pt; position:absolute; top:10pt; left:10pt; right:10pt; border:1pt solid red");
my $vp = PDF::Style::Viewport.new;

my $pdf = PDF::Content::PDF.new;
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
    my $box = $vp.box( :$text, :$css );
    @html.push: $box.html;
    $box.render($page);

    my $box-width = $box.right - $box.left;
    my $expected-width = $test-width eq 'long'
        ?? $vp.width - $css.left - $css.right - $css.border-left-width - $css.border-right-width
        !! %Width{$test-width};

    is-approx $box-width, $expected-width, 'box width';

##    if ++$n %% 2 {
        $css.top += 75pt;
##        $css.left = 20pt;
##    }
##    else {
##        $css.left += 270pt;
##    }
}

lives-ok {$pdf.save-as: "t/widths.pdf"};

@html.append: $vp.html-end, '</body>', '</html>', '';
"t/widths.html".IO.spurt: @html.join: "\n";

done-testing;
