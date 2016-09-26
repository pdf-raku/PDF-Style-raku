use v6;

class PDF::Style::Box {
    use PDF::Style :pt;
    use CSS::Declarations;
    use CSS::Declarations::Units;
    use HTML::Entity;
    use Color;

    my Int enum Edges is export(:Edges) <Top Right Bottom Left>;
    
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

    submethod BUILD(Numeric :$!top!, Numeric :$!left!,
                    Numeric :$width, Numeric :$height,
                    Numeric :$!bottom = $!top - $height,
                    Numeric :$!right = $!left + $width,
                    Numeric :$!em = 12pt, Numeric :$!ex = 9pt,
                    CSS::Declarations :$!css!,
                    :$!content,
                   ) {
    }

    method translate( \x = 0, \y = 0) {
        self.Array = [ $!top    + y, $!right + x,
                       $!bottom + y, $!left  + x ];
    }

    method !length($qty) {
        { :thin(1pt), :medium(2pt), :thick(3pt) }{$qty} // pt($qty, :$!em, :$!ex)
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
                $!padding = $!border = $!margin = Nil;
                $!top    = $v[Top] // 0;
                $!right  = $v[Right] // self.top;
                $!bottom = $v[Bottom] // self.top;
                $!left   = $v[Left] // self.right
            });
    }

    my subset LineStyle of Str where 'none'|'hidden'|'dotted'|'dashed'|'solid'|'double'|'groove'|'ridge'|'inset'|'outset';
    method !dash-pattern(LineStyle $_) {
        when 'dashed' { [[3.2,], 0] }
        when 'dotted' { [[1.6,], 0] }
        default       { [[], 0] }
    }

    method !border($gfx) {
        my %border = $!css.border;
        my @border = self.border.list;
        my @width = %border<border-width>.map: {self!length($_)};
        @border[Left] += @width[Left]/2;
        @border[Right] -= (@width[Left] + @width[Right])/2;
        @border[Top] -= @width[Top]/2;
        @border[Bottom] += (@width[Top] + @width[Bottom])/2;

        if @width.unique == 1
        && %border<border-color>.map(*.Str).unique == 1
        && %border<border-style>.unique == 1 {
            # all 4 edges are the same. draw a simple rectangle
            if @width[0] {
                $gfx.LineWidth = @width[0];
                my Color \color = %border<border-color>[0];
                $gfx.StrokeAlpha = color.a / 255;
                $gfx.StrokeColor = :DeviceRGB[ color.rgb.map: ( */255 ) ];
                $gfx.DashPattern = self!dash-pattern( %border<border-style>[0] );
                my \w = @border[Right] - @border[Left];
                my \h = @border[Top] - @border[Bottom];
                $gfx.Rectangle(@border[Left], @border[Bottom], w, h);
                $gfx.CloseStroke;
            }
        }
        else {
            for (Top, Right, Bottom, Left) -> $edge {
                with @width[$edge] -> \width {
                    if width {
                        $gfx.LineWidth = width;
                        my Color \color = %border<border-color>[$edge];
                        $gfx.StrokeAlpha = color.a / 255;
                        $gfx.StrokeColor = :DeviceRGB[ color.rgb.map: ( */255 ) ];
                        $gfx.DashPattern = self!dash-pattern( %border<border-style>[$edge] );
                        my Numeric \pos = @border[$edge];
                        if $edge == Top|Bottom {
                            $gfx.MoveTo( @border[Left], pos);
                            $gfx.LineTo( @border[Right], pos);
                        }
                        else {
                            $gfx.MoveTo( pos, @border[Top] );
                            $gfx.LineTo( pos, @border[Bottom] );
                        }
                        $gfx.CloseStroke;
                    }
                }
            }
        }
    }

    method style($gfx) {
        self!border($gfx)
    }

    method pdf($page) {
        $page.graphics: {
            self.style($_);
            $page.text: {
                my $left = self.left;
                my $top = self.top;
                .print(self.content, :position[ :$left, :$top]);
            }
        }
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
