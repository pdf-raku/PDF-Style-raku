use v6;

class PDF::Style::Box {
    use PDF::Style :pt;
    use CSS::Declarations;
    use CSS::Declarations::Units;
    use HTML::Entity;
    use PDF::Content::Text::Block;
    use PDF::Content::Util::Font;
    use Color;

    my Int enum Edges is export(:Edges) <Top Right Bottom Left>;
    
    has Numeric $.em is rw;
    has Numeric $.ex is rw;

    has Numeric $.top;
    has Numeric $.right;
    has Numeric $.bottom;
    has Numeric $.left;
    has Numeric $.width;
    has Numeric $.height;

    has Array $!padding;
    has Array $!border;
    has Array $!margin;

    has CSS::Declarations $.css;
    has $.content;

    my subset FontWeight of Numeric where { 100 .. 900 && $_ %% 100 }
    has FontWeight $.font-weight = 400;
    has Hash @.save;

    submethod BUILD(
        CSS::Declarations :$!css = CSS::Declarations.new,
        Numeric :$!em = 12pt, Numeric :$!ex = 0.75 * $!em,
        Numeric :$!top = 0.0, Numeric :$!left = 0.0,
        Numeric :$!width = self.css-width($!css) || 595pt,
        Numeric :$!height = self.css-height($!css) || 842pt,
        Numeric :$!bottom = $!top - $!height,
        Numeric :$!right = $!left + $!width,
        :$!content,
                   ) {
    }

    method translate( \x = 0, \y = 0) {
        self.Array = [ $!top    + y, $!right + x,
                       $!bottom + y, $!left  + x ];
    }

    method !length($v) {
        pt($v, :$!em, :$!ex);
    }

    method !width($qty) {
        { :thin(1pt), :medium(2pt), :thick(3pt) }{$qty} // self!length($qty)
    }

    method !widths(List $qtys) {
        [ $qtys.map: { self!width($_) } ]
    }

    method padding returns Array {
        $!padding //= $.enclose($.Array, self!widths($!css.padding));
    }
    method border returns Array {
        $!border //= $.enclose($.padding, self!widths($!css.border-width));
    }
    method margin returns Array {
        $!margin //= $.enclose($.border, self!widths($!css.margin));
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

    method !draw-border($gfx) {
        my %border = $!css.border;
        my Numeric @border[4] = self.border.list;
        my Numeric @width[4] = %border<border-width>.map: {self!width($_)};
        my @stroke = [
            @border[Top] - @width[Top]/2,
            @border[Right] - @width[Right]/2,
            @border[Bottom] + @width[Bottom]/2,
            @border[Left] + @width[Left]/2,
        ];

        if @width.unique == 1
        && %border<border-color>.map(*.Str).unique == 1
        && %border<border-style>.unique == 1
        && %border<border-color>[0].a != 0 { # not transparent
            # all 4 edges are the same. draw a simple rectangle
            if @width[0] {
                $gfx.LineWidth = @width[0];
                my Color \color = %border<border-color>[0];
                $gfx.StrokeAlpha = color.a / 255;
                $gfx.StrokeColor = :DeviceRGB[ color.rgb.map: ( */255 ) ];
                $gfx.DashPattern = self!dash-pattern( %border<border-style>[0] );

                my \w = @stroke[Right] - @stroke[Left];
                my \h = @stroke[Top] - @stroke[Bottom];
                $gfx.Rectangle(@stroke[Left], @stroke[Bottom], w, h);

                $gfx.CloseStroke;
            }
        }
        else {
            # edges differ. draw them separately
            for (Top, Right, Bottom, Left) -> $edge {
                with @width[$edge] -> \width {
                    if width {
                        $gfx.LineWidth = width;
                        my Color \color = %border<border-color>[$edge];
                        next if color.a == 0; # transparent
                        $gfx.StrokeAlpha = color.a / 255;
                        $gfx.StrokeColor = :DeviceRGB[ color.rgb.map: ( */255 ) ];
                        $gfx.DashPattern = self!dash-pattern( %border<border-style>[$edge] );
                        my Numeric \pos = @stroke[$edge];
                        if $edge == Top|Bottom {
                            $gfx.MoveTo( @stroke[Left], pos);
                            $gfx.LineTo( @stroke[Right], pos);
                        }
                        else {
                            $gfx.MoveTo( pos, @stroke[Top] );
                            $gfx.LineTo( pos, @stroke[Bottom] );
                        }
                        $gfx.CloseStroke;
                    }
                }
            }
        }
        with $!css.background-color {
            my Bool \transparent = .a == 0;
            unless transparent {
                $gfx.FillColor = :DeviceRGB[ .rgb.map: ( */255 ) ];
                $gfx.FillAlpha = .a / 255;
                my Numeric @inner[4] = [
                    @border[Top] - @width[Top],
                    @border[Right] - @width[Right],
                    @border[Bottom] + @width[Bottom],
                    @border[Left] + @width[Left],
                ];
                my \w = @inner[Right] - @inner[Left];
                my \h = @inner[Top] - @inner[Bottom];
                $gfx.Rectangle(@inner[Left], @inner[Bottom], w, h);
                $gfx.Fill;
            }
        }
    }

    method !set-font-color($gfx) {
        with $!css.color {
            $gfx.FillColor = :DeviceRGB[ .rgb.map: ( */255 ) ];
            $gfx.FillAlpha = .a / 255;
        }
        else {
            $gfx.FillColor = :DeviceGray[0.0];
            $gfx.FillAlpha = 1.0;
        }
    }

    method style($gfx) {
        self!draw-border($gfx);
    }

    method render($page) {
        $page.graphics: {
            self.style($_);
            self!set-font-color($_);
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

    method save {
        @!save.push: {
            :$!width, :$!height, :$!em, :$!ex, :$!font-weight,
        }
    }

    method restore {
        if @!save {
            with @!save.pop {
                $!width       = .<width>;
                $!height      = .<height>;
                $!em          = .<em>;
                $!ex          = .<ex>;
                $!font-weight = .<font-weight>;
            }
        }
    }

    #| converts a weight name to a three digit number:
    #| 100 lightest ... 900 heaviest
    method !font-weight($_) returns FontWeight {
        given .lc {
            when FontWeight       { $_ }
            when /^ <[1..9]>00 $/ { .Int }
            when 'normal'         { 400 }
            when 'bold'           { 700 }
            when 'lighter'        { max($!font-weight - 100, 100) }
            when 'bolder'         { min($!font-weight + 100, 900) }
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
                !! self!length($_);
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

    method css-height($css) {
        my Numeric $height = $_ with self!length($css.height);
        with self!length($css.max-height) {
            $height = $_
                if $height.defined && $height > $_;
        }
        with self!length($css.min-height) {
            $height = $_
                if $height.defined && $height < $_;
        }
        $height;
    }

    method css-width($css) {
        my Numeric $width = $_ with self!length($css.width);
        with self!length($css.max-width) {
            $width = $_
                if !$width.defined || $width > $_;
        }
        with self!length($css.min-width) {
            $width = $_
                if $width.defined && $width < $_;
        }
        $width;
    }

    method !build-content($css, $class, %opt) {
        my $top = self!length($css.top);
        my $bottom = self!length($css.bottom);

        my $height = self.css-height($css);
        my \max-height = $height // self.height - ($top//0) - ($bottom//0);


        my $left = self!length($css.left);
        my $right = self!length($css.right);
        my $width = self.css-width($css);
        my \max-width = $width // self.width - ($left//0) - ($right//0);
        $width //= max-width if $left.defined && $right.defined;

        my $content = $class.new: |%opt, :width(max-width), :height(max-height);

        $width //= $content.actual-width;
        with self!length($css.min-width) -> \min {
            $width = min if min > $width
        }

        $height //= $content.actual-height;
        with self!length($css.min-height) -> \min {
            $height = min if min > $height
        }

        my Bool \from-left = $left.defined;
        unless from-left {
            $left = $right.defined
                ?? self.width - $right - $width
                !! 0;
        }

        my Bool \from-top = $top.defined;
        unless from-top {
            $top = $bottom.defined
                ?? self.height - $bottom - $height
                !! 0;
        }

        #| adjust from PDF coordinates. Shift origin from top-left to bottom-left;
        my \pdf-top = self.height - $top;
        my \box = PDF::Style::Box.new: :$css, :$left, :top(pdf-top), :$width, :$height, :$!em, :$!ex, :$content;

        # reposition to outside of border
        my Numeric @content-box[4] = box.Array.list;
        my Numeric @border-box[4]  = box.border.list;
        my \dx = from-left
               ?? @content-box[Left]  - @border-box[Left]
               !! @content-box[Right] - @border-box[Right];
        my \dy = from-top
               ?? @content-box[Top]    - @border-box[Top]
               !! @content-box[Bottom] - @border-box[Bottom];

        box.translate(dx, dy);
        box;
    }

    method text-box( Str $text, CSS::Declarations :$css!, Str :$valign is copy) {

        my $family = $css.font-family // 'arial';
        my $font-style = $css.font-style // 'normal';
        $!font-weight = self!font-weight($css.font-weight // 'normal');
        my Str $weight = $!font-weight >= 700 ?? 'bold' !! 'normal'; 

        my $font = PDF::Content::Util::Font::core-font( :$family, :$weight, :style($font-style) );
        my $font-size = self!font-length($css.font-size);
        $!em = $font-size;
        $!ex = $font-size * $_ / 1000
            with $font.XHeight;

        my $leading = do given $css.line-height {
            when .key eq 'num' { $_ * $font-size }
            when .key eq 'percent' { $_ * $font-size / 100 }
            when 'normal' { $font-size * 1.2 }
            default       { self!length($_) }
        }

        my $kern = $css.font-kerning
            && ( $css.font-kerning eq 'normal'
                 || ($css.font-kerning eq 'auto' && $!em <= 32));

        my $align = $css.text-align && $css.text-align eq 'left'|'right'|'center'|'justify'
            ?? $css.text-align
            !! 'left';

        $valign //= 'top';
        my %opt = :$text, :$font, :$kern, :$font-size, :$leading, :$align, :$valign;

        %opt<CharSpacing> = do given $css.letter-spacing {
            when .key eq 'num'     { $_ * $font-size }
            when .key eq 'percent' { $_ * $font-size / 100 }
            when 'normal' { 0.0 }
            default       { self!length($_) }
        }

        %opt<WordSpacing> = do given $css.word-spacing {
            when 'normal' { 0.0 }
            default       { self!length($_) - $font.stringwidth(' ', $font-size) }
        }

        self!build-content($css, PDF::Content::Text::Block, %opt);
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
