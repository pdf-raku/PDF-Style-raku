use v6;
use Test;
use PDF::Style :pt;
use PDF::Style::Viewport;
use PDF::Style::Box;
use CSS::Declarations;
use CSS::Declarations::Units;
use PDF::Content::PDF;

# also dump to HTML, for comparision

my $css = CSS::Declarations.new: :style("font-family:Helvetica; width:250pt; position:absolute; top:10pt; left:20pt; border:1pt solid red");
my $vp = PDF::Style::Viewport.new;

my $pdf = PDF::Content::PDF.new;
my $page = $vp.add-page($pdf);
$page.gfx.comment-ops = True;
$page.media-box = [0, 0, pt($vp.width), pt($vp.height) ];
my @html = '<html>', '<body>', $vp.html-start;
my $n;

constant %Height = %('_' => Mu, '-' => 50pt, '=' => 75pt, '+' => 100pt);

my %seen;

for [ '_=_' => '=',
      '-_+' => 'snug',
      '+=-' => '+',
      '-+=' => '=',
      '_+=' => '=',
      '+=_' => '+',
      '_=+' => '=',
      '+_=' => '+',
      '-__' => '-',
      '___' => 'snug',
    ] {
    warn "duplicate test: {.key}" if %seen{.key}++;
    my ($min-height, $height, $max-height) = .key.comb.map: { %Height{$_} };
    my $test-height = .value;

    $css.delete($_) for <height min-height max-height>;
    $css.min-height = $_ with $min-height;
    $css.height = $_ with $height;
    $css.max-height = $_ with $max-height;

    my $style = $css.write;
    my $text = (++$n,.value, ':', .key, $style).join: ' ';
    my $box = $vp.box( :$text, :$css );
    @html.push: $box.html;
    $box.render($page);

    my $box-height = $box.top - $box.bottom;
    my $expected-height = $test-height eq 'snug'
        ?? $box.text.content-height
        !! %Height{$test-height};

    is-approx $box-height, $expected-height, 'box height';

    if $n %% 2 {
        $css.top += 120pt;
        $css.left = 20pt;
    }
    else {
        $css.left += 270pt;
    }
}

lives-ok {$pdf.save-as: "t/heights.pdf"};

@html.append: $vp.html-end, '</body>', '</html>', '';
"t/heights.html".IO.spurt: @html.join: "\n";

done-testing;
