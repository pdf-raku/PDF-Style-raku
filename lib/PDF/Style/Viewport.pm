use v6;

class PDF::Style::Viewport {

    use PDF::Content;
    use PDF::Content::Util::Font;
    use CSS::Declarations;
    use CSS::Declarations::Units;
    use PDF::Style :pt;
    use PDF::Style::Box;

    has Numeric $.width = 595pt;
    has Numeric $.height = 842pt;
    has Numeric $.em = 12pt;
    has Numeric $.ex = 9pt;
    my subset FontWeight of Numeric where { 100 .. 900 && $_ %% 100 }
    has FontWeight $!font-weight = 400;

    #| converts a weight name to a three digit number:
    #| 100 lightest ... 900 heaviest
    method !weight($_) returns FontWeight {
        given .lc {
            when FontWeight       { $_ }
            when /^ <[1..9]>00 $/ { .Int }
            when 'normal'         { 400 }
            when 'bold'           { 700 }
            when 'lighter'        { max($!font-weight - 100, 100) }
            when 'bolder'         { min($!font-weight + 100, 900) }
            default { die "unknown font weight: $_"; }
        }
    }

    method !length($v) {
        pt($v, :$!em, :$!ex);
    }

    method text( Str $text, CSS::Declarations :$css!, Str :$valign is copy) {

        my $family = $css.font-family // 'arial';
        my $font-style = $css.font-style // 'normal';
        $!font-weight = self!weight($css.font-weight // 'normal');
        my Str $weight = $!font-weight >= 700 ?? 'bold' !! 'normal'; 

        my Numeric $font-size = { :medium(12pt), :large(16pt), :small(9pt) }{$css.font-size} // self!length($css.font-size) // 12pt;
        my $font = PDF::Content::Util::Font::core-font( :$family, :$weight, :style($font-style) );
        $!em = $font-size;
        $!ex = $font-size * $_ / 1000
            with $font.XHeight;

        my $css-top = self!length($css.top);
        my $bottom = self!length($css.bottom);

        my Numeric $height = $_ with self!length($css.height);
        with self!length($css.max-height) {
            $height = $_
                if !$height.defined || $height > $_;
        }
        with self!length($css.min-height) {
            $height = $_
                if $height.defined && $height < $_;
        }

        my $max-height = $height // self.height - ($css-top//0) - ($bottom//0);

        my $left = self!length($css.left);
        my $right = self!length($css.right);
        my Numeric $width = $_ with self!length($css.width);
        with self!length($css.max-width) {
            $width = $_
                if !$width.defined || $width > $_;
        }
        with self!length($css.min-width) {
            $width = $_
                if $width.defined && $width < $_;
        }

        my $max-width = $width // self.width - ($left//0) - ($right//0);
        $width //= $max-width if $left.defined && $right.defined;

        my $line-height = self!length($css.line-height) // $font-size * 1.2;

        my $kern = $css.font-kerning
            && ( $css.font-kerning eq 'normal'
                 || ($css.font-kerning eq 'auto' && $font-size <= 32));

        my $align = $css.text-align && $css.text-align eq 'left'|'right'|'center'|'justify'
            ?? $css.text-align
            !! 'left';

        $valign //= 'top';
        my %opt = :$text, :$font, :$kern, :$font-size, :$line-height, :$align, :$valign, :width($max-width), :height($max-height);

        my $text-block = PDF::Content::Text::Block.new: |%opt;

        $width //= $text-block.actual-width;
        with self!length($css.min-width) -> $min {
            $width = $min if $min > $width
        }
        $left //= $right.defined
            ?? self.width - $right - $width
            !! 0;

        $height //= $text-block.actual-height;
        with self!length($css.min-height) -> $min {
            $height = $min if $min > $height
        }
        $css-top //= $bottom.defined
            ?? self.height - $bottom - $height
            !! 0;

        #| adjust from PDF cordinates. Shift origin from top-left to bottom-left;
        my $top = self!length($.height) - $css-top;

        PDF::Style::Box.new: :$css, :$left, :$top, :$width, :$height, :$!em, :$!ex, :content($text-block);
    }

}
