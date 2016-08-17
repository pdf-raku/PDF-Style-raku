use v6;

class PDF::Style::Box {
    use PDF::Style :pt;
    use CSS::Declarations;
    use CSS::Declarations::Units;
    use HTML::Entity;

    my Int enum Sides <Top Right Bottom Left>;
    
    has Numeric $.em;
    has Numeric $.ex;

    has Numeric $.top;
    has Numeric $.right;
    has Numeric $.bottom;
    has Numeric $.left;

    has Array $!padding;
    has Array $!border;
    has Array $!margin;

    has CSS::Declarations $.css;
    has $.content;

    submethod BUILD(Numeric :$!top!, Numeric :$!left!, CSS::Declarations:$!css!,
                    Numeric :$width, Numeric :$height,
                    Numeric :$!bottom = $!top - $height,
                    Numeric :$!right = $!left + $width,
                    Numeric :$!em = 12pt, Numeric :$!ex = 3/4 * $!em,
                            :$!content,
                   ) {
    }

    method !length($qty) {
        $qty ~~ Numeric
            ?? pt($qty, :$!em, :$!ex)
            !! pt($qty)
    }

    method !lengths(List $qtys) {
        [ $qtys.map: { self!length($_) } ]
    }

    method padding returns Array {
        $!padding //= $.enclose(self!lengths($.Array), self!lengths($!css.padding));
    }
    method border returns Array {
        $!border //= $.enclose($.padding, self!lengths($!css.border-width));
    }
    method margin returns Array {
        $!margin //= $.enclose($.border, self!lengths($!css.margin));
    }

    method enclose(List $inner, List $outer) {
        [
         $inner[Top]    + $outer[Top],
         $inner[Right]  + $outer[Right],
         $inner[Bottom] - $outer[Bottom],
         $inner[Left]   - $outer[Left],
        ]
    }

    method Array is rw {
        Proxy.new(
            FETCH => sub ($) {
                [$!top, $!right, $!bottom, $!left]
            },
            STORE => sub ($,$v is copy) {
                $v = [$v,] unless $v.isa(List);
                $!top    = $v[Top] // 0;
                $!right  = $v[Right] // self.top;
                $!bottom = $v[Bottom] // self.top;
                $!left   = $v[Left] // self.right
            });
    }

    method !dash-pattern(Str $line-style) {
        my subset LineStyle of Str where 'none'|'hidden'|'dotted'|'dashed'|'solid'|'double'|'groove'|'ridge'|'inset'|'outset';
        given $line-style {
            when 'dashed' { [[8,], 0] }
            when 'dotted' { [[2,], 0] }
            default       { [[], 0] }
        }
    }

    method !border($gfx) {
        for <top right bottom left> -> $edge {
            with $!css."border-{$edge}-width"() {
                $gfx.SetLineWidth( pt($_) );
                my $color = $!css."border-{$edge}-color"() // 255 xx 3;
                $gfx.SetStrokeRGB( |$color.map: ( */255 ) );
                $gfx.SetDash( |self!dash-pattern($!css."border-{$edge}-style"()) );
                my $pos = self."border-{$edge}"();
                if $edge eq 'top'|'bottom' {
                    $gfx.MoveTo( self.border-left, $pos);
                    $gfx.LineTo( self.border-right, $pos);
                }
                else {
                    $gfx.MoveTo( $pos, self.border-top );
                    $gfx.LineTo( $pos, self.border-bottom );
                }
                $gfx.CloseStroke;
            }
        }
    }

    method style($gfx) {
        self!border($gfx)
    }

    method html {
        my $style = encode-entities($!css.write);
        my $text = encode-entities($!content.text);
        $text = sprintf '<div style="position:relative; top:%dpt">%s</div>', $!content.top-offset, $text
            if $!content.top-offset;

        sprintf '<div style="%s">%s</div>', $style, $text;
    }

    #| absolute positions
    multi method FALLBACK($meth where /^ (padding|border|margin)'-'(top|right|bottom|left) $/) {
        my Str $box = ~$0;
        my UInt $edge = %( :top(Top), :right(Right), :bottom(Bottom), :left(Left) ){ $1 };
        self.^add_method($meth, method { self."$box"()[$edge] });
        self."$meth"();
    }

    #| cumulative widths and heights
    multi method FALLBACK($meth where /^ (padding|border|margin)'-'(width|height) $/) {
        my Str $box = ~$0;
        my &meth = do given ~$1 {
            when 'width'  { method { .[Right] - .[Left] with self."$box"() } }
            when 'height' { method { .[Top] - .[Bottom] with self."$box"() } }
        };
        self.^add_method($meth, &meth);
        self."$meth"();
    }
}
