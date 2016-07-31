use v6;

class PDF::Style::Box {
    use PDF::Style :pt;
    use CSS::Declarations;
    use CSS::Declarations::Units;

    my Int enum Sides <Top Right Bottom Left>;
    
    has Length $.em = 16px;
    has Length $.ex = 10px;

    has Numeric $.top;
    has Numeric $.right;
    has Numeric $.bottom;
    has Numeric $.left;
 
    has CSS::Declarations $.css;

    submethod BUILD(Numeric :$!top!, Numeric :$!left!, CSS::Declarations:$!css!,
                    Numeric :$width, Numeric :$height,
                    Numeric :$!bottom = $!top - $height,
                    Numeric :$!right = $!left + $width) {
        
    }

    method !dim($_ --> Numeric) {
        when 'em' { $!em }
        when 'ex' { $!ex }
        default   { Units.enums{$_}
                    or die "unknown length unit: $_" }
    }

    method !length(Numeric $qty) {
        pt($qty)
    }

    method !lengths(List $qtys) {
        [ $qtys.map: { self!length($_) } ]
    }

    method padding returns Array {
        $.enclose(self!lengths($.Array), self!lengths($!css.padding));
    }
    method border returns Array {
        $.enclose($.padding, self!lengths($!css.border-width));
    }
    method margin returns Array {
        $.enclose($.border, self!lengths($!css.margin));
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
                $v = [$v] unless $v.isa(List);
                $!top    = $v[Top] // 0;
                $!right  = $v[Right] // self.top;
                $!bottom = $v[Bottom] // self.top;
                $!left   = $v[Left] // self.right
            });
    }

    method !border($gfx) {
        for <top right bottom left> -> $edge {
            with $!css."border-{$edge}-width"() {
                $gfx.SetLineWidth( $_ );
                my $color = $!css."border-{$edge}-color"() // 255 xx 3;
                $gfx.SetStrokeRGB(|$color.map: ( */255 ));
                my $pos = self."border-{$edge}"();
                if $edge eq 'top'|'bottom' {
                    $gfx.MoveTo( self.border-left, $pos);
                    $gfx.LineTo( self.border-right, $pos);
                }
                else {
                    $gfx.MoveTo( $pos, self.border-top );
                    $gfx.LineTo( $pos, self.border-bottom );
                }
                $gfx.ClosePath;
                $gfx.Stroke;
            }
        }
    }

    method style($gfx) {
        self!border($gfx)
    }

    multi method FALLBACK($meth where /^ (padding|border|margin)'-'(top|right|bottom|left) $/) {
        my Str $box = ~$0;
        my UInt $edge = %( :top(Top), :right(Right), :bottom(Bottom), :left(Left) ){ $1 };
        self.^add_method($meth, method {
                                self."$box"()[$edge]
                                });
        self."$meth"();
    }

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
