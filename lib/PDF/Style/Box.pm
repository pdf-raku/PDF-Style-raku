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

    submethod BUILD(:$!top!, :$!left!, :$!css!,
                    :$width, :$height,
                    :$!bottom = $!top - $width,
                    :$!right = $!left + $width) {
        
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

    method style($gfx) {
        with $!css.border-top-width {
            $gfx.SetLineWidth( $_ );
            $gfx.SetStrokeRGB(|.map: ( */255 ))
                with $!css.border-top-color;
            $gfx.MoveTo( $.border-left, $.border-top);
            $gfx.LineTo( $.border-right, $.border-top);
            $gfx.ClosePath;
            $gfx.Stroke;
        }
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
            when 'width'  { method { .[Right] - .[Left] with self."box"() } }
            when 'height' { method { .[Bottom] - .[Top] with self."box"() } }
        };
        self.^add_method($meth, &meth);
        self."$meth"();
    }
}
