use v6;
use CSS::Declarations:ver(v0.3.1 .. *);

class PDF::Style::Element {
    use HTML::Entity;
    use PDF::Style::Font:ver(v0.0.1 .. *);
    use PDF::Content:ver(v0.0.4 .. *);
    use PDF::Content::Image;
    use PDF::Content::Text::Block;
    use PDF::Content::Util::TransformMatrix;
    use PDF::DAO::Stream;
    use Color;
    use CSS::Declarations::Units :Scale, :pt;

    my class ImageContent {
        has PDF::DAO::Stream $.image handles <width height data-uri>;
        has Numeric  $.x-scale is rw = Scale::px;
        has Numeric  $.y-scale is rw = Scale::px;
        method content-width  { self.width * self.x-scale }
        method content-height { self.height * self.y-scale }
    }

    use CSS::Declarations::Box :Edges;
    has CSS::Declarations::Box $.box handles<left top bottom right width height css>;
    has ImageContent $.image;
    has PDF::Content::Text::Block $.text;
    has $.canvas;

    submethod TWEAK(
        Numeric :$em = 12pt,
        Numeric :$ex = 0.75 * $em,
        |c
    ) {
        my $font = PDF::Style::Font.new: :$em, :$ex;
        $!box //= CSS::Declarations::Box.new( :$font, |c);
    }

    my subset LineStyle of Str where 'none'|'hidden'|'dotted'|'dashed'|'solid'|'double'|'groove'|'ridge'|'inset'|'outset';
    method !dash-pattern(LineStyle $line-style, Numeric :$width!, Numeric :$length) {
        my @phases = do given $line-style {
            when 'dashed' { [$width * 3,] }
            when 'dotted' { [$width,] }
            default       { [] }
        }
        [ @phases, 0];
    }

    #| Do basic styling, common to all box types (image, text, canvas)
    method !style-box($_) {
        my Numeric @border[4] = self.box.border.list;
        @border[$_] -= $.left for Left, Right;
        @border[$_] -= $.bottom for Top, Bottom;

        .graphics: -> $gfx {
            self!render-background-color($gfx, @border, $_)
                with $.css.background-color;

            my $bg-image = $.css.background-image;
            unless $bg-image ~~ 'none' {
                $bg-image = PDF::Content::Image.open($bg-image)
                    unless $bg-image ~~ PDF::DAO::Stream;
                self!render-background-image($gfx, $bg-image);
            }

            self!render-border($gfx, @border);
        }
    }

    method !render-border($gfx, @border) {
        my %border = $.css.border;
        my Numeric @width[4] = self.box.widths(%border<border-width>);
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
                    my $width = @width[0];
                    $gfx.LineWidth = $width;
                    $gfx.StrokeAlpha = color.a / 255;
                    $gfx.StrokeColor = :DeviceRGB[ color.rgb.map: ( */255 ) ];
                    $gfx.DashPattern = self!dash-pattern( %border<border-style>[0], :$width );

                    my \w = @stroke[Right] - @stroke[Left];
                    my \h = @stroke[Top] - @stroke[Bottom];
                    $gfx.Rectangle(@stroke[Left], @stroke[Bottom], w, h);

                    $gfx.Stroke;
                }
            }
        }
        else {
            # edges differ. draw them separately
            for (Top, Right, Bottom, Left) -> \edge {
                with @width[edge] -> $width {
                    my $border-style = %border<border-style>[edge];
                    with %border<border-color>[edge] -> Color \color {
                        if $width && $border-style ne 'none' && color.a != 0 {
                            $gfx.LineWidth = $width;
                            $gfx.StrokeAlpha = color.a / 255;
                            $gfx.StrokeColor = :DeviceRGB[ color.rgb.map: ( */255 ) ];
                            my Numeric \pos = @stroke[edge];
                            if edge == Top|Bottom {
                                $gfx.DashPattern = self!dash-pattern( $border-style, :$width, :length(@stroke[Left] - @stroke[Right]) );
                                $gfx.MoveTo( @stroke[Left], pos);
                                $gfx.LineTo( @stroke[Right], pos);
                            }
                            else {
                                $gfx.DashPattern = self!dash-pattern( $border-style, :$width, :length(@stroke[Top] - @stroke[Bottom]) );
                                $gfx.MoveTo( pos, @stroke[Top] );
                                $gfx.LineTo( pos, @stroke[Bottom] );
                            }
                        }
                        $gfx.Stroke;
                    }
                }
            }
        }
    }

    method !set-font-color($gfx) {
        with $.css.color {
            $gfx.FillColor = :DeviceRGB[ .rgb.map: ( */255 ) ];
            $gfx.FillAlpha = .a / 255;
        }
        else {
            $gfx.FillColor = :DeviceGray[0.0];
            $gfx.FillAlpha = 1.0;
        }
        $gfx.StrokeAlpha = 1.0;
    }

    method !render-background-color($gfx, @border, Color $_) {
        unless .a == 0 {
            $gfx.FillColor = :DeviceRGB[ .rgb.map: ( */255 ) ];
            $gfx.FillAlpha = .a / 255;
            my \w = @border[Right] - @border[Left];
            my \h = @border[Top] - @border[Bottom];
            $gfx.Rectangle(@border[Left], @border[Bottom], w, h);
            $gfx.Fill;
        }
    }

    method !pdf {require PDF::Lite:ver(v0.0.1..*)}

    has %!pattern-cache{Any};
    method !render-background-image($gfx, $bg-image) {
        my $repeat-x = True;
        my $repeat-y = True;
        given $.css.background-repeat {
            when 'repeat-y' { $repeat-x = False }
            when 'repeat-x' { $repeat-y = False }
            when 'no-repeat' { $repeat-x = $repeat-y = False }
        }
        my Array \padding = self.box.padding;
        my Array \border = self.box.border;
        my \bg-width = border[Right] - border[Left];
        my \bg-height = border[Top] - border[Bottom];
        $gfx.Save;
        $gfx.transform: :translate[ padding[Left] - $.left, padding[Top] - $.bottom];

        my @bg-region = border[Left] - padding[Left], padding[Bottom] - border[Bottom], bg-width, -bg-height;
        my $width = $bg-image.width * Scale::px;
        my $height = $bg-image.height * Scale::px;
        my \x-float = padding[Right] - padding[Left] - $width;
        my \y-float = padding[Top] - padding[Bottom] - $height;
        my ($x, $y) = self!align-background-image(x-float, y-float);
        if ($width >= bg-width && $height >= bg-height)
        || (!$repeat-x && !$repeat-y) {
            # doesn't repeat no tiling pattern required
            $gfx.Rectangle(|@bg-region);
            $gfx.Clip;
            $gfx.EndPath;
            $gfx.do($bg-image, $x, -$y, :$width, :$height, :valign<top>);
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
                @Matrix = PDF::Content::Util::TransformMatrix::transform( :matrix(@Matrix), :translate[0, bg-height] );
            }

            @Matrix = PDF::Content::Util::TransformMatrix::transform( :matrix(@Matrix), :translate[$x, -$y] )
                if $x || $y;
            my $pattern = self!pdf.tiling-pattern(:BBox[0, 0, $width, $height], :@Matrix, :$XStep, :$YStep );

            $pattern.graphics: {
                .do($bg-image, 0, 0, :$width, :$height );
            }
            $pattern.finish;

            $gfx.FillColor = :Pattern($gfx.resource-key($pattern));
            $gfx.Rectangle: |@bg-region;
            $gfx.Fill;
        }
 
        $gfx.Restore;
    }

    multi sub bg-pos(Str $v, $float, :%keyw!) {
        (%keyw{$v} // 0) * $float;
    }
    multi sub bg-pos(Numeric $v, $float, :$keyw) {
        given $v.type {
            when 'percent' { $v * $float / 100 }
            default        { 0pt + $v }
        }
    }

    method !align-background-image($x-float, $y-float) {
        enum <x y>;
        my @pos = $.css.background-position.list;
        @pos.push('center') while @pos < 2;
        @pos = @pos.reverse
            if @pos[x] eq 'top'|'bottom' || @pos[y] eq 'left'|'right';

        my $x = bg-pos(@pos[x], $x-float, :keyw{ :left(0.0), :center(0.5), :right(1.0) });
        my $y = bg-pos(@pos[y], $y-float, :keyw{ :top(0.0), :center(0.5), :bottom(1.0) });
        $x, $y;
    }

    method !render($gfx) {
        self!style-box($gfx);

        with $!image {
            my $image = .image;
            my $width = .content-width;
            my $height = .content-height;
            
            $gfx.do($image, :$width, :$height);
        }
        with $!text -> \text {
            my $top = $.top - $.bottom;
            self!set-font-color($gfx);
            $gfx.BeginText;
            $gfx.print(text, :position[ :left(0), :$top]);
            $gfx.EndText;
        }
        with $!canvas -> \canvas {
            canvas.font-object //= PDF::Style::Font.new;
            my \image = self!pdf.xobject-form: :BBox[0, 0, $.width, $.height];
            image.gfx.draw(canvas);
            image.finish;

            $gfx.do(image, :$.width, :$.height);
        }
    }

    method render($page) {
        my $opacity = $.css.opacity.Num;
        if $opacity =~= 1 {
            $page.graphics: -> $gfx {
                $gfx.transform: :translate[ $.left, $.bottom ];
                self!render($gfx);
            }
        }
        elsif $opacity !=~= 0 {
            # apply opacity to an image group as a whole
            my Numeric @b[4] = self.box.border.list;
            my @BBox = [@b[Left] - $.left, @b[Bottom] - $.bottom, @b[Right] - $.left, @b[Top] - $.bottom];
            my \image = self!pdf.xobject-form: :@BBox;
            image<Group> = { :S( :name<Transparency> ) };
            image.graphics: {
                self!render($_);
            }
            image.finish;
            $page.graphics: -> $gfx {
                $gfx.FillAlpha = $gfx.StrokeAlpha = $opacity;
                $gfx.do(image, $.left, $.bottom);
            }
        }
    }

    method html {
        my $css = $.css.clone;
        $css.delete('vertical-align'); # we'll deal with this later
        my $style = $css.write;

        with $!canvas {
            .to-html(:$.width, :$.height, :$style);
        }
        else {
            my $style-att = $style
                ?? encode-entities($style).fmt: ' style="%s"'
                !! '';

            with $!image {
                '<img%s src="%s"/>'.sprintf($style-att, .data-uri);
            }
            else {
                my $text = do with $!text {
                    encode-entities(.text);
                }
                else {
                    ''
                }
                with $.css.vertical-align -> $valign {
                    unless $valign eq 'baseline' {
                    # wrap content in a table cell for valign to take affect
                        $text = '<table width="100%%" height="100%%" cellspacing=0 cellpadding=0><tr><td style="vertical-align:%s">%s</td></tr></table>'.sprintf($valign, $text);
                    }
                }

                '<div%s>%s</div>'.sprintf($style-att, $text);
            }
        }
    }

    method !length($v) {
        self.box.font.length($v);
    }

    #| create and position a child box
    method !place-child-box(CSS::Declarations $css, &build-content) {
        my $top = self!length($css.top);
        my $bottom = self!length($css.bottom);
        my $left = self!length($css.left);
        my $right = self!length($css.right);
        my $width = self.box.css-width($css);
        my $height = self.box.css-height($css);

        my \height-max = do with $height {
            $_
        }
        else {
            my $max = $.height - ($top//0) - ($bottom//0);
            for <padding-top padding-bottom border-top-width border-bottom-width> {
                $max -= $_ with self!length($css."$_"());
            }
            $max;
        }

        my \width-max = $width // do {
            my $max = $.width - ($left//0) - ($right//0);
            for <padding-left padding-right border-left-width border-right-width> {
                $max -= $_ with self!length($css."$_"());
            }
            $max;
        }

        my subset ContentType where 'canvas'|'image'|'text';
        my (ContentType $type, $content) = (.key, .value)
            with &build-content( :width(width-max), :height(height-max) );

        $width //= width-max if $left.defined && $right.defined;
        $width //= .content-width with $content;
        with self!length($css.min-width) -> \min {
            $width = min if min > $width
        }

        $height //= .content-height with $content;
        with self!length($css.min-height) -> \min {
            $height = min if min > $height
        }

        my Bool \from-left = $left.defined;
        unless from-left {
            $left = $right.defined
                ?? $.width - $right - $width
                !! 0;
        }

        my Bool \from-top = $top.defined;
        unless from-top {
            $top = $bottom.defined
                ?? $.height - $bottom - $height
                !! 0;
        }

        #| adjust from PDF coordinates. Shift origin from top-left to bottom-left;
        my \pdf-top = $.height - $top;
        my $em = $.box.font.em;
        my $ex = $.box.font.ex;
        my \elem = self.element-class.new: :$css, :$left, :top(pdf-top), :$width, :$height, :$em, :$ex, |($type => $content);
        my \box = elem.box;

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
        elem;
    }

    #| class to use for creating child boxes
    method element-class {
        self
    }

    #| create a child element. Positioning is relative to this object. CSS styles
    #| are inherited from this object.
    multi method element( Str:D :$text!,
			  CSS::Declarations :$css is copy = self.css,
			  Bool :$inherit = True) {

	# inherit styles from this element
	$css = $css.new( :copy($css), :inherit(self.css) )
	    if $inherit && $css !=== self.css;

        my $font = self.box.font.setup($css);
        my $kern = $css.font-kerning eq 'normal' || (
            $css.font-kerning eq 'auto' && $font.em <= 32
        );

        my $align = $css.text-align;
        my $font-size = $font.em;
        my $leading = $font.line-height / $font-size;
        my $face = $font.face;

        # support a vertical-align subset
        my $valign = do given $css.vertical-align {
            when 'middle' { 'center' }
            when 'top'|'bottom' { $_ }
            default { 'top' };
        }
        my %opt = :font($face), :$kern, :$font-size, :$leading, :$align, :$valign;

        %opt<CharSpacing> = do given $css.letter-spacing {
            when .type eq 'num'     { $_ * $font-size }
            when .type eq 'percent' { $_ * $font-size / 100 }
            when 'normal' { 0.0 }
            default       { $font.length($_) }
        }

        %opt<WordSpacing> = do given $css.word-spacing {
            when 'normal' { 0.0 }
            default       { $font.length($_) - $font.face.stringwidth(' ', $font-size) }
        }
        my &content-builder = sub (|c) { text => PDF::Content::Text::Block.new( :$text, :baseline<top>, |%opt, |c) };
        self!place-child-box($css, &content-builder);
    }

    multi method element( Str:D :$image!, CSS::Declarations :$css!) {
        my $width = self.box.css-width($css);
        my $height = self.box.css-height($css);
        my &content-builder = sub (|c) {
            my \image = ImageContent.new( :image($_) )
                with PDF::Content::Image.open($image);
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
            image => image;
        }
        self!place-child-box($css, &content-builder);
    }

    multi method element( :$canvas!, :$css!) {
        my &content-builder = sub (|c) { :$canvas };
        self!place-child-box($css, &content-builder);
    }

    multi method element( :$css! ) is default {
        self!place-child-box($css, sub (|c) {});
    }

}
