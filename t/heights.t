use v6;
use Test;
use PDF::Style::Viewport;
use PDF::Style::Element;
use CSS::Properties;
use CSS::Properties::Units :pt, :ops;
use PDF::Lite;

# also dump to HTML, for comparision

my CSS::Properties $css .= new: :style("font-family:Helvetica; width:250pt; position:absolute; top:10pt; left:20pt; border:1pt solid red");
my PDF::Style::Viewport $vp .= new;

my PDF::Lite $pdf .= new;
my $page = $vp.decorate: $pdf.add-page;
$page.gfx.comment-ops = True;
$page.media-box = [0, 0, ($vp.width)pt, ($vp.height)pt ];
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
    my $elem = $vp.element( :$text, :$css );
    @html.push: $elem.html;
    $page.gfx.do(.xobject, .left, .bottom) with $elem;

    my $elem-height = $elem.top - $elem.bottom;
    my $expected-height = $test-height eq 'snug'
        ?? $elem.text.content-height
        !! %Height{$test-height};

    is-approx $elem-height, $expected-height, 'box height';

    if $n %% 2 {
        $css.top ➕= 120pt;
        $css.left = 20pt;
    }
    else {
        $css.left ➕= 270pt;
    }
}

lives-ok {$pdf.save-as: "t/heights.pdf"};

@html.append: $vp.html-end, '</body>', '</html>', '';
"t/heights.html".IO.spurt: @html.join: "\n";

done-testing;
