use v6;
class PDF::Style::Font {
    use PDF::Style :pt;
    use CSS::Declarations;
    use CSS::Declarations::Units;
    use PDF::Content::Util::Font;

    has Numeric $.em is rw;
    has Numeric $.ex is rw;
    my subset FontWeight of Numeric where { 100 .. 900 && $_ %% 100 }
    has FontWeight $.weight is rw = 400;
    has Str $.family;
    has Str $.style;
    has $.face;
    has Numeric $.leading;

    method length($v) {
        pt($v, :$!em, :$!ex);
    }

    #| converts a weight name to a three digit number:
    #| 100 lightest ... 900 heaviest
    method !weight($_) returns FontWeight {
        given .lc {
            when FontWeight       { $_ }
            when /^ <[1..9]>00 $/ { .Int }
            when 'normal'         { 400 }
            when 'bold'           { 700 }
            when 'lighter'        { max($!weight - 100, 100) }
            when 'bolder'         { min($!weight + 100, 900) }
            default {
                warn "unhandled font-weight: $_";
                400;
            }
        }
    }

    method !font-length($_) returns Numeric {
        if $_ ~~ Numeric {
            return .?key ~~ 'percent'
            ?? $!em * $_ / 100
            !! self.length($_);
        }
        given .lc {
            when 'xx-small' { 6pt }
            when 'x-small'  { 7.5pt }
            when 'small'    { 10pt }
            when 'medium'   { 12pt }
            when 'large'    { 13.5pt }
            when 'x-large'  { 18pt }
            when 'xx-large' { 24pt }
            when 'larger'   { $!em * 1.2 }
            when 'smaller'  { $!em / 1.2 }
            default {
                warn "unhandled font-size: $_";
                12pt;
            }
        }
    }

    has CSS::Declarations $!css;
    #| parses a CSS font specification
    #| e.g. $font.parse: 'italic bold 10pt/12pt sans-serif';
    method parse(Str $font-css) {
        $!css //= CSS::Declarations.new;
        $!css.font = $font-css;
        self.setup;
    }

    method setup(CSS::Declarations $css = $!css) {
        $!family = $css.font-family // 'arial';
        $!style = $css.font-style;
        $!weight = self!weight($css.font-weight);
        my Str $weight = $!weight >= 700 ?? 'bold' !! 'normal'; 

        $!face = PDF::Content::Util::Font::core-font( :$!family, :$weight, :$!style );
        $!em = self!font-length($css.font-size);
        $!ex = $!em * $_ / 1000
            with $!face.XHeight;

        $!leading = do given $css.line-height {
            when .key eq 'num'     { $_ * $!em }
            when .key eq 'percent' { $_ * $!em / 100 }
            when 'normal'          { $!em * 1.2 }
            default                { self.length($_) }
        }
    }
}

