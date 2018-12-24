use v6;

use PDF::Style;

class PDF::Style::Element
    is PDF::Style {
    use PDF::Style::Font;
    use PDF::Content::Graphics;
    use PDF::Content::XObject;
    use PDF::Content::Matrix :transform;
    use Color;
    use CSS::Properties :measure;
    use CSS::Properties::Units :Scale, :pt;

    use CSS::Properties::Box :Edges;
    has CSS::Properties::Box $.box handles<Array left top bottom right width height css> is rw;

    submethod TWEAK(
        Numeric :$em = 12pt,
        Numeric :$ex = 0.75 * $em,
        |c
    ) {
        my PDF::Style::Font $font .= new: :$em, :$ex;
        $!box //= CSS::Properties::Box.new( :$font, |c);
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
        my Numeric @border[4] = $!box.border.list;
        @border[$_] -= $.left for Left, Right;
        @border[$_] -= $.bottom for Top, Bottom;

        .graphics: -> $gfx {
            self!render-background-color($gfx, @border, $_)
                with $.css.background-color;

            my $bg-image = $.css.background-image;
            unless $bg-image ~~ 'none' {
                $bg-image = PDF::Content::XObject.open($bg-image)
                    unless $bg-image ~~ PDF::Content::XObject;
                self!render-background-image($gfx, $bg-image);
            }

            self!render-border($gfx, @border);
        }
    }

    method !render-border($gfx, @border) {
        my %border = $.css.border;
        my Numeric @width[4] = $!box.widths(%border<border-width>);
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
            given %border<border-color>[0] -> \color {
                my \border-style = %border<border-style>[0];
                if @width[0] && border-style ne 'none' && color.a != 0 {
                    my $width = @width[0];
                    $gfx.LineWidth = $width;
                    $gfx.StrokeAlpha = color.a / 255;
                    $gfx.StrokeColor = :DeviceRGB[ color.rgb.map: */255 ];
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
                given @width[edge] -> $width {
                    my $border-style = %border<border-style>[edge];
                    given %border<border-color>[edge] -> Color \color {
                        if $width && $border-style ne 'none' && color.a !=~= 0 {
                            $gfx.LineWidth = $width;
                            $gfx.StrokeAlpha = color.a / 255;
                            $gfx.StrokeColor = :DeviceRGB[ color.rgb.map: */255 ];
                            my Numeric \pos = @stroke[edge];
                            if edge ~~ Top|Bottom {
                                $gfx.DashPattern = self!dash-pattern( $border-style, :$width, :length(@stroke[Left] - @stroke[Right]) );
                                $gfx.MoveTo( @stroke[Left], pos);
                                $gfx.LineTo( @stroke[Right], pos);
                            }
                            else {
                                $gfx.DashPattern = self!dash-pattern( $border-style, :$width, :length(@stroke[Top] - @stroke[Bottom]) );
                                $gfx.MoveTo( pos, @stroke[Top] );
                                $gfx.LineTo( pos, @stroke[Bottom] );
                            }
                            $gfx.Stroke;
                        }
                    }
                }
            }
        }
    }

    method !render-background-color($gfx, @border, Color $_) {
        unless .a == 0 {
            $gfx.FillColor = :DeviceRGB[ .rgb.map: */255 ];
            $gfx.FillAlpha = .a / 255;
            my \w = @border[Right] - @border[Left];
            my \h = @border[Top] - @border[Bottom];
            $gfx.Rectangle(@border[Left], @border[Bottom], w, h);
            $gfx.Fill;
        }
    }

    has %!pattern-cache{Any};
    method !render-background-image($gfx, $bg-image) {
        my Bool (\repeat-x, \repeat-y) = do given $.css.background-repeat {
            when 'repeat'   { True, True }
            when 'repeat-x' { True, False }
            when 'repeat-y' { False, True }
            default         { False, False }
        };
        my List \padding = $!box.padding;
        my List \border = $!box.border;
        my \bg-width = border[Right] - border[Left];
        my \bg-height = border[Top] - border[Bottom];
        my @bg-region = border[Left] - padding[Left], padding[Bottom] - border[Bottom], bg-width, -bg-height;
        my $width = $bg-image.width * Scale::px;
        my $height = $bg-image.height * Scale::px;
        my \x-float = padding[Right] - padding[Left] - $width;
        my \y-float = padding[Top] - padding[Bottom] - $height;
        my (\x, \y) = self!align-background-image(x-float, y-float);

        $gfx.Save;
        $gfx.transform: :translate[ padding[Left] - $.left, padding[Top] - $.bottom];

        if ($width >= bg-width && $height >= bg-height)
        || (!repeat-x && !repeat-y) {
            # doesn't repeat no tiling pattern required
            $gfx.Rectangle(|@bg-region);
            $gfx.Clip;
            $gfx.EndPath;
            $gfx.do($bg-image, x, -y, :$width, :$height, :valign<top>);
        }
        else {
            my @Matrix[6] = $gfx.CTM.list;
            my Numeric $XStep = $width;
            my Numeric $YStep = $height;

            unless repeat-x {
                # step outside box in X direction
                $XStep += bg-width;
            }
            unless repeat-y {
                # step outside box in Y direction
                $YStep += bg-height;
                @Matrix = transform( :matrix(@Matrix), :translate[0, bg-height] );
            }

            @Matrix = transform( :matrix(@Matrix), :translate[x, -y] )
                if x || y;
            my $pattern = $gfx.tiling-pattern(:BBox[0, 0, $width, $height], :@Matrix, :$XStep, :$YStep );

            $pattern.gfx.do($bg-image, 0, 0, :$width, :$height );
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
        enum <X Y>;
        my @pos = $.css.background-position.list;
        @pos.push('center') while @pos < 2;
        @pos = @pos.reverse
            if @pos[X] eq 'top'|'bottom' || @pos[Y] eq 'left'|'right';

        my \x = bg-pos(@pos[X], $x-float, :keyw{ :left(0.0), :center(0.5), :right(1.0) });
        my \y = bg-pos(@pos[Y], $y-float, :keyw{ :top(0.0), :center(0.5), :bottom(1.0) });
        x, y;
    }

    method !bbox {
        my Numeric @b[4] = $!box.border.list;
        [@b[Left] - $.left, @b[Bottom] - $.bottom, @b[Right] - $.left, @b[Top] - $.bottom];
    }

    method !xobject(:$comment) {
        # apply opacity to an image group as a whole
        my @BBox = self!bbox;
        my \image = PDF::Content::Graphics.xobject-form: :@BBox;
        image.graphics: -> $gfx {
            $gfx.add-comment($_) with $comment;
            self!style-box($gfx);
            self.render-element($gfx);
        }
        image.finish;
        image;
    }

    method xobject(|c) {
        my $opacity = $.css.opacity.Num;
        my $xobject = self!xobject();

        unless $opacity =~= 1 {
           # need to wrap it, to apply transparency.
           my @BBox = self!bbox;
           my $outer = PDF::Content::Graphics.xobject-form: :@BBox;
           $outer.graphics: {
               .FillAlpha = .StrokeAlpha = $opacity;
               .do($xobject, 0, 0);
           }
           $xobject = $outer;
        }
        $xobject;
    }

    #| create and position content within a containing box
    method place-element(CSS::Properties :$css!,
                         :&build-content = sub (|c) {},
                         CSS::Properties::Box :$container!) {

        my $em = $container.font.em;
        my $ex = $container.font.ex;
        sub length($v) {
            state $vh = $container.height / 100;
            state $vw = $container.width / 100;
            measure($v, :$em, :$ex, :$vw, :$vh)
        }

        my $top    = length($css.top);
        my $bottom = length($css.bottom);
        my $height = $container.css-height($css);

        my \height-max = $height // do {
            my $max = $container.height - ($top//0) - ($bottom//0);
            for <padding-top padding-bottom border-top-width border-bottom-width> {
                $max -= $_ with length($css."$_"());
            }
            $max;
        }

        my $left  = length($css.left);
        my $right = length($css.right);
        my $width = $container.css-width($css);

        my \width-max = $width // do {
            my $max = $container.width - ($left//0) - ($right//0);
            for <padding-left padding-right border-left-width border-right-width> {
                $max -= $_ with length($css."$_"());
            }
            $max;
        }

        my subset ContentType where 'canvas'|'image'|'text';
        my (ContentType $type, $content) = (.key, .value)
            with &build-content( :width(width-max), :height(height-max) );

        $width //= width-max if $left.defined && $right.defined;
        $width //= .content-width with $content;
        with length($css.min-width) -> \min {
            $width = min if min > $width
        }

        $height //= .content-height with $content;
        with length($css.min-height) -> \min {
            $height = min if min > $height
        }

        my Bool \from-left = $left.defined;
        unless from-left {
            $left = $right.defined
                ?? $container.width - $right - $width
                !! 0;
        }

        my Bool \from-top = $top.defined;
        unless from-top {
            $top = $bottom.defined
                ?? $container.height - $bottom - $height
                !! 0;
        }

        #| adjust from PDF coordinates. Shift origin from top-left to bottom-left;
        my \pdf-top = $container.height - $top;
        my \elem = self.new: :$css, :$left, :top(pdf-top), :$width, :$height, :$em, :$ex, |($type => $content);
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

}
