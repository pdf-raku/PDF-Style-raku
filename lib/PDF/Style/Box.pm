use v6;
use PDF; # otherwise, canvas.t failed with: No such symbol 'PDF::Lite'

class PDF::Style::Box {
    use PDF::Style::Font;
    use CSS::Declarations;
    use CSS::Declarations::Units;
    use HTML::Entity;
    use PDF::Content::Image;
    use PDF::Content::Text::Block;
    use PDF::Content::Util::TransformMatrix;
    use PDF::DAO::Stream;
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
    has $.canvas;

    has Hash @.save;

    my subset BoundingBox of Str where 'content'|'border'|'margin'|'padding';

    multi method top { $!top }
    multi method top(BoundingBox $box) {
        self."$box"()[Top];
    }

    multi method right { $!right }
    multi method right(BoundingBox $box) {
        self."$box"()[Right];
    }

    multi method bottom { $!bottom }
    multi method bottom(BoundingBox $box) {
        self."$box"()[Bottom]
    }

    multi method left { $!left }
    multi method left(BoundingBox $box) {
        self."$box"()[Left]
    }

    multi method width { $!width }
    multi method width(BoundingBox $box) {
        my \box = self."$box"();
        box[Right] - box[Left]
    }

    multi method height { $!height }
    multi method height(BoundingBox $box) {
        my \box = self."$box"();
        box[Top] - box[Bottom]
    }

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

    method content returns Array { self.Array }

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
                $!right  = $v[Right] // $!top;
                $!bottom = $v[Bottom] // $!top;
                $!left   = $v[Left] // $!right
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
        my Numeric @width[4] = %border<border-width>.map: {self!width($_)};
        my Numeric @border[4] = self.border.list;
        @border[$_] -= $!left for Left, Right;
        @border[$_] -= $!bottom for Top, Bottom;

        .graphics: -> $gfx {
            self!render-background-color($gfx, @border, $_)
                with $!css.background-color;

            my $bg-image = $!css.background-image;
            if $bg-image ne 'none' {
                $bg-image = PDF::Content::Image.open($bg-image)
                    unless $bg-image ~~ PDF::DAO::Stream;
                self!render-background-image($gfx, $bg-image);
            }

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
                with %border<border-color>[0] -> \color {
                    my \border-style = %border<border-style>[0];
                    if @width[0] && border-style ne 'none' && color.a != 0 {
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
            }
            else {
                # edges differ. draw them separately
                for (Top, Right, Bottom, Left) -> $edge {
                    with @width[$edge] -> \width {
                        my \border-style = %border<border-style>[$edge];
                        with %border<border-color>[$edge] -> Color \color {
                            if width && border-style ne 'none' && color.a != 0 {
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
                            }
                            $gfx.CloseStroke;
                        }
                    }
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
        $gfx.StrokeAlpha = 1.0;
    }

    sub rectangles-overlap(@ra, @rb) {
        my enum <Left Bottom Width Height>;
        @ra[Left]   < (@rb[Left] + @rb[Width])
        && @rb[Left]   < (@ra[Left] + @ra[Width])
        && @ra[Bottom] < (@rb[Bottom] + @rb[Height])
        && @rb[Bottom] < (@ra[Bottom] + @ra[Height]);
    }

    method !render-background-color($gfx, @border, $_) {
        unless .a == 0 {
            $gfx.FillColor = :DeviceRGB[ .rgb.map: ( */255 ) ];
            $gfx.FillAlpha = .a / 255;
            my \w = @border[Right] - @border[Left];
            my \h = @border[Top] - @border[Bottom];
            $gfx.Rectangle(@border[Left], @border[Bottom], w, h);
            $gfx.Fill;
        }
    }

    method !render-background-image($gfx, $bg-image) {
        my $repeat-x = True;
        my $repeat-y = True;
        given $!css.background-repeat {
            when 'repeat-y' { $repeat-x = False }
            when 'repeat-x' { $repeat-y = False }
            when 'no-repeat' { $repeat-x = $repeat-y = False }
        }
        my Array \padding = self.padding;
        my Array \border = self.border;
        my \bg-width = border[Right] - border[Left];
        my \bg-height = border[Top] - border[Bottom];
        $gfx.Save;
        $gfx.transform: :translate[ padding[Left] - $!left, padding[Top] - $!bottom];

        my @bg-region = border[Left] - padding[Left], padding[Bottom] - border[Bottom], bg-width, -bg-height;

        my $width = $bg-image.width * Units::px;
        my $height = $bg-image.height * Units::px;
        if ($width >= bg-width && $height >= bg-height)
        || (!$repeat-x && !$repeat-y) {
            # doesn't repeat no tiling pattern required
            $gfx.Rectangle(|@bg-region);
            $gfx.Clip;
            $gfx.EndPath;
            $gfx.do($bg-image, 0, 0, :$width, :$height, :valign<top>);
        }
        else {
            my @Matrix = $gfx.CTM.list;

            my $XStep = $width;
            my $YStep = $height;

            unless $repeat-x {
                # step outside box in X direction
                $XStep += bg-width;
            }
            unless $repeat-y {
                # step outside box in Y direction
                $YStep += bg-height;
                @Matrix = PDF::Content::Util::TransformMatrix::transform-matrix( :matrix(@Matrix), :translate[0, bg-height] );
            }

            my $pattern = (require PDF::Lite).tiling-pattern(:BBox[0, 0, $width, $height], :@Matrix, :$XStep, :$YStep );

            $pattern.graphics: {
                .do($bg-image, 0, 0, :$width, :$height );
            }
            $pattern.finish;
            $gfx.FillColor = :Pattern($gfx.resource-key($pattern));
            $gfx.Rectangle(|@bg-region);
            $gfx.Fill;
        }
 
        $gfx.Restore;
    }

    method !render($gfx) {
        self!style-box($gfx);

        with $!image -> \image {
            my $width = image.content-width;
            my $height = image.content-height;
            
            $gfx.do(image, :$width, :$height);
        }
        with $!text -> \text {
            my $top = $!top - $!bottom;
            self!set-font-color($gfx);
            $gfx.BeginText;
            $gfx.print(text, :position[ :left(0), :$top]);
            $gfx.EndText;
        }
        with $!canvas -> \canvas {
            canvas.font-object //= PDF::Style::Font.new;
            my \image = (require PDF::Lite).xobject-form: :bbox[0, 0, $!width, $!height];
            image.gfx.draw(canvas);
            image.finish;

            $gfx.do(image, :$!width, :$!height);
        }
    }

    method render($page) {
        my $opacity = $!css.opacity.Num;
        if $opacity =~= 1 {
            $page.graphics: -> $gfx {
                $gfx.transform: :translate[ $!left, $!bottom ];
                self!render($gfx);
            }
        }
        elsif $opacity !=~= 0 {
            my Numeric @b[4] = self.border.list;
            my @BBox = [@b[Left] - $!left, @b[Bottom] - $!bottom, @b[Right] - $!left, @b[Top] - $!bottom];
            my \image = (require PDF::Lite).xobject-form: :@BBox;
            image<Group> = { :S( :name<Transparency> ) };
            image.graphics: {
                self!render($_);
            }
            image.finish;
            $page.graphics: -> $gfx {
                $gfx.FillAlpha = $gfx.StrokeAlpha = $opacity;
                $gfx.do(image, $!left, $!bottom);
            }
        }
    }

    method html {
        my $css = $!css.clone;
        $css.delete('vertical-align'); # we'll deal with this later
        my $style = $css.write;
        my $style-html = encode-entities($style);

        with $!text {
            my $text = encode-entities(.text);
            with $!css.vertical-align -> $valign {
                unless $valign eq 'baseline' {
                    # wrap content in a table cell for valign to take affect
                    $text = sprintf '<table width="100%%" height="100%%" cellspacing=0 cellpadding=0><tr><td style="vertical-align:%s">%s</td></tr></table>', $valign, $text;
                }
            }

            sprintf '<div style="%s">%s</div>', $style-html, $text;
        }
        else {
            with $!image {
                sprintf '<img style="%s" src="%s"/>', $style-html, .data-uri;
            }
            else {
                .to-html(:$!width, :$!height, :$style) with $!canvas;
            }
        };

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
            my $max = $!height - ($top//0) - ($bottom//0);
            for <padding-top padding-bottom border-top-width border-bottom-width> {
                $max -= $_ with $css."$_"();
            }
            $max;
        }

        my \width-max = do with $width {
            $_
        }
        else {
            my $max = $!width - ($left//0) - ($right//0);
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
                ?? $!width - $right - $width
                !! 0;
        }

        my Bool \from-top = $top.defined;
        unless from-top {
            $top = $bottom.defined
                ?? $!height - $bottom - $height
                !! 0;
        }

        #| adjust from PDF coordinates. Shift origin from top-left to bottom-left;
        my \pdf-top = $!height - $top;
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

    multi method box( Str:D :$text!, CSS::Declarations :$css!) {

        self.font.setup($css);
        my $kern = $css.font-kerning eq 'normal' || (
            $css.font-kerning eq 'auto' && $.em <= 32
        );

        my $align = $css.text-align;
        my $leading = $!font.leading;
        my $font-size = $!font.em;
        my $font = $!font.face;
        # support a veritical-align subset
        my $valign = do given $css.vertical-align {
            when 'middle' { 'center' }
            when 'top'|'bottom' { $_ }
            default { 'top' };
        }
        my %opt = :$font, :$kern, :$font-size, :$leading, :$align, :$valign;

        %opt<CharSpacing> = do given $css.letter-spacing {
            when .type eq 'num'     { $_ * $font-size }
            when .type eq 'percent' { $_ * $font-size / 100 }
            when 'normal' { 0.0 }
            default       { $!font.length($_) }
        }

        %opt<WordSpacing> = do given $css.word-spacing {
            when 'normal' { 0.0 }
            default       { $!font.length($_) - $!font.face.stringwidth(' ', $font-size) }
        }
        my &content-builder = sub (|c) { text => PDF::Content::Text::Block.new( :$text, :baseline<top>, |%opt, |c) };
        self!build-box($css, &content-builder);
    }

    multi method box( Str:D :$image!, CSS::Declarations :$css!) {
        my role ImageBox {
            has Numeric  $.x-scale is rw = Units::px;
            has Numeric  $.y-scale is rw = Units::px;
            method content-width  { self.width * self.x-scale }
            method content-height { self.height * self.y-scale }
        }
        my $width = self.css-width($css);
        my $height = self.css-height($css);
        my &content-builder = sub (|c) {
            my \image = PDF::Content::Image.open($image) does ImageBox;
            die "unable to determine image width" unless image.width;
            die "unable to determine image height" unless image.height;
            if $width {
                image.x-scale = $width / image.width;
                image.y-scale = $height
                    ?? $height / image.height
                    !! image.x-scale;
            }
            elsif $height {
                image.y-scale = $height / image.height;
                image.x-scale = image.y-scale;
            }
            image => image
        }
        self!build-box($css, &content-builder);
    }

    multi method box( :$canvas!, :$css!) {
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
