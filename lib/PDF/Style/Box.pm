use v6;

class PDF::Style::Box {
    use PDF::Style::Font;
    use CSS::Declarations;
    use CSS::Declarations::Units;
    use HTML::Entity;
    use PDF::Content::Image;
    use PDF::Content::Text::Block;
    use PDF::DAO::Stream;
    use HTML::Canvas;
    use Color;

    my Int enum Edges is export(:Edges) <Top Right Bottom Left>;

    has Numeric $.top;
    has Numeric $.right;
    has Numeric $.bottom;
    has Numeric $.left = 0;
    has Numeric $.width = 595pt;
    has Numeric $.height = 842pt;

    has Array $!padding;
    has Array $!border;
    has Array $!margin;

    has PDF::Style::Font $.font handles <em ex>;

    has CSS::Declarations $.css;
    has PDF::DAO::Stream $.image;
    has PDF::Content::Text::Block $.text;
    has HTML::Canvas $.canvas;

    has Hash @.save;

    submethod TWEAK(
        Numeric :$!top = $!height,
        Numeric :$!bottom = $!top - $!height,
        Numeric :$!right = $!left + $!width,
        Numeric :$em = 12pt, Numeric :$ex = 0.75 * $em,
        Str :$style = '',
        CSS::Declarations :$!css = CSS::Declarations.new(:$style),
    ) {
        $!font = PDF::Style::Font.new: :$em, :$ex;
    }

    method !length($v) {
        self.font.length($v);
    }

    method translate( \x = 0, \y = 0) {
        self.Array = [ $!top    + y, $!right + x,
                       $!bottom + y, $!left  + x ];
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

    #| Do basic styling, common to all box types (image, text, canvas)
    method !style-box($_) {
        my %border = $!css.border;
        my Numeric @border[4] = self.border.list;
        my Numeric @width[4] = %border<border-width>.map: {self!width($_)};
        .graphics: -> $gfx {
            my @stroke = [
                @border[Top] - @width[Top]/2,
                @border[Right] - @width[Right]/2,
                @border[Bottom] + @width[Bottom]/2,
                @border[Left] + @width[Left]/2,
            ];

            if @width.unique == 1
            && %border<border-color>.map({($_//'').Str}).unique == 1
            && %border<border-style>.unique == 1 {
                # all 4 edges are the same. draw a simple rectangle
                my \border-style = %border<border-style>[0];
                my Color \color = $_
                with %border<border-color>[0];
                if @width[0] && border-style ne 'none' && color && color.a != 0 {
                    $gfx.LineWidth = @width[0];
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
                        my \border-style = %border<border-style>[$edge];
                        my Color \color = $_
                        with %border<border-color>[$edge];
                        if width && border-style ne 'none' && color && color.a != 0 {
                            $gfx.LineWidth = width;
                            $gfx.StrokeAlpha = color.a / 255;
                            $gfx.StrokeColor = :DeviceRGB[ color.rgb.map: ( */255 ) ];
                            $gfx.DashPattern = self!dash-pattern(  border-style );
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
                    my \w = @border[Right] - @border[Left];
                    my \h = @border[Top] - @border[Bottom];
                    $gfx.Rectangle(@border[Left], @border[Bottom], w, h);
                    $gfx.Fill;
                }
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

    method render($page) {
        $page.graphics: -> $gfx {
            self!style-box($gfx);
            my $left = self.left;
            my $bottom = self.bottom;
            with $!image -> \image {
                $gfx.Save;
                $gfx.transform: :translate[ $left, $bottom ];
                my $width = image.content-width;
                my $height = image.content-height;
                $gfx.do(image, :$width, :$height);
                $gfx.Restore;
            }
            with $!text -> \text {
                my $top = self.top;
                self!set-font-color($gfx);
                $page.text: {
                    .print(text, :position[ :$left, :$top]);
                }
            }
            with $!canvas -> \canvas {
                my $width = self.width;
                my $height = self.height;
                canvas.font-object //= PDF::Style::Font.new;
                use HTML::Canvas::To::PDF;
                my HTML::Canvas::To::PDF $canvas-pdf-renderer .= new: :$gfx, :$width, :$height;
                $gfx.Save;
                $gfx.transform: :translate[ $left, $bottom ];
                canvas.render($canvas-pdf-renderer);
                $gfx.Restore;
            }
        }
    }

    method html {
        my $style = $!css.write;
        my $style-html = encode-entities($style);
        my $text;
        with $!text {
            $text = encode-entities(.text);
            $text = sprintf '<div style="position:relative; top:%dpt">%s</div>', $!text.top-offset, $text
                if $!text.top-offset;
            sprintf '<div style="%s">%s</div>', $style-html, $text;
        }
        else {
            with $!image {
                use Base64;
                my $path = .path;
                my $raw = $path.IO.slurp(:bin);
                my $enc = encode-base64($raw, :str);
                my $type = lc PDF::Content::Image.image-type($path);
                sprintf '<img style="%s" src="data:image/%s;base64,%s"/>', $style-html, $type, $enc;
            }
            else {
                my $width = self.width;
                my $height = self.height;
                .html(:$width, :$height, :$style) with $!canvas;
            }
        }
    }

    method save {
        my $em = $!font.em;
        my $ex = $!font.ex;
        my $font-weight = $!font.weight;
        @!save.push: {
            :$!width, :$!height, :$em, :$ex, :$font-weight,
        }
    }

    method restore {
        if @!save {
            with @!save.pop {
                $!width       = .<width>;
                $!height      = .<height>;
                $!font.em     = .<em>;
                $!font.ex     = .<ex>;
                $!font.weight = .<font-weight>;
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

    method !build-box($css, &build-content) {
        my $top = self!length($css.top);
        my $bottom = self!length($css.bottom);
        my $left = self!length($css.left);
        my $right = self!length($css.right);
        my $width = self.css-width($css);
        my $height = self.css-height($css);

        my \height-max = do with $height {
            $_
        }
        else {
            my $max = self.height - ($top//0) - ($bottom//0);
            for <padding-top padding-bottom border-top-width border-bottom-width> {
                $max -= $_ with $css."$_"();
            }
            $max;
        }

        my \width-max = do with $width {
            $_
        }
        else {
            my $max = self.width - ($left//0) - ($right//0);
            for <padding-left padding-right border-left-width border-right-width> {
                $max -= $_ with $css."$_"();
            }
            $max;
        }

        my ($type, $content) = (.key, .value)
            with &build-content( :width(width-max), :height(height-max) );

        $width //= width-max if $left.defined && $right.defined;
        $width //= $content.content-width;
        with self!length($css.min-width) -> \min {
            $width = min if min > $width
        }

        $height //= $content.content-height;
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
        my \box = PDF::Style::Box.new: :$css, :$left, :top(pdf-top), :$width, :$height, :$.em, :$.ex, |($type => $content);

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

    multi method box( Str:D :$text!, CSS::Declarations :$css!, Str :$valign) {

        self.font.setup($css);
        my $kern = $css.font-kerning eq 'normal' || (
            $css.font-kerning eq 'auto' && $.em <= 32
        );

        my $align = $css.text-align // (
            $css.direction eq 'ltr' ?? 'left' !! 'right'
        );

        my $leading = $!font.leading;
        my $font-size = $!font.em;
        my $font = $!font.face;
        my %opt = :$font, :$kern, :$font-size, :$leading, :$align;

        %opt<CharSpacing> = do given $css.letter-spacing {
            when .key eq 'num'     { $_ * $font-size }
            when .key eq 'percent' { $_ * $font-size / 100 }
            when 'normal' { 0.0 }
            default       { $!font.length($_) }
        }

        %opt<WordSpacing> = do given $css.word-spacing {
            when 'normal' { 0.0 }
            default       { $!font.length($_) - $!font.face.stringwidth(' ', $font-size) }
        }
        %opt<valign> = $valign // 'top';
        my &content-builder = sub (|c) { text => PDF::Content::Text::Block.new( :$text, |%opt, |c) };
        self!build-box($css, &content-builder);
    }

    multi method box( :$image! where Str|PDF::DAO::Stream, CSS::Declarations :$css!) {
        my role ImageBox {
            has Numeric  $.x-scale is rw = 1.0;
            has Numeric  $.y-scale is rw = 1.0;
            has IO::Path $.path is rw;
            method content-width  { self<Width> * self.x-scale }
            method content-height { self<Height> * self.y-scale }
        }
        my $width = self.css-width($css);
        my $height = self.css-height($css);
        my &content-builder = sub (|c) {
            my \image = ($image.isa(PDF::DAO::Stream)
                         ?? $image
                         !! PDF::Content::Image.open($image)
                        ) does ImageBox;
            image.path = $image.IO;
            if $width {
                image.x-scale = $width / image<Width>;
                if $height {
                    image.y-scale = $height / image<Height>;
                }
                else {
                    image.y-scale = image<Height> / image<Width> * $.x-scale;
                }
            }
            elsif $height {
                image.y-scale = $height / image<Height>;
                image.x-scale = image<Width>  / image<Height> * image.y-scale;
            }
            image => image
        }
        self!build-box($css, &content-builder);
    }

    multi method box( HTML::Canvas :$canvas!, :$css!) {
        my &content-builder = sub (|c) { :$canvas };
        self!build-box($css, &content-builder);
    }

    method can(Str \name) {
       my @meth = callsame;
       if !@meth {
           given name {
               when /^ (padding|border|margin)'-'(top|right|bottom|left) $/ {
                   #| absolute positions
                   my Str $box = ~$0;
                   my UInt $edge = %( :top(Top), :right(Right), :bottom(Bottom), :left(Left) ){$1};
                   @meth.push: method { self."$box"()[$edge] };
               }
               when /^ (padding|border|margin)'-'(width|height) $/ {
                   #| cumulative widths and heights
                   my Str $box = ~$0;
                   @meth.push: do given ~$1 {
                       when 'width'  { method { .[Right] - .[Left] with self."$box"() } }
                       when 'height' { method { .[Top] - .[Bottom] with self."$box"() } }
                   }
               }
           }
           self.^add_method(name, @meth[0]) if @meth;
       }
       @meth;
    }
    method dispatch:<.?>(\name, |c) is raw {
        self.can(name) ?? self."{name}"(|c) !! Nil
    }
    method FALLBACK(Str \name, |c) {
        self.can(name)
            ?? self."{name}"(|c)
            !! die die X::Method::NotFound.new( :method(name), :typename(self.^name) );
    }
}
