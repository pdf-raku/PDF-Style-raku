use v6;

class PDF::Style::Basic {

    use Color;

    use PDF::Content;
    use PDF::Content::Color :color, :gray;
    use PDF::Content::Matrix :transform;

    use PDF::Style::Font;

    use CSS::Units :Lengths, :pt;
    use CSS::Box :Edges;
    use CSS::Font;

    has CSS::Box $.box handles<Array left top bottom right width height css translate border> is rw;

    submethod TWEAK(Numeric :$em = 12pt, :gfx($), :base-url($), :font-face($), |c) {
        $!box //= do {
            my PDF::Style::Font $font .= new: :$em, |c;
            CSS::Box.new: :$font, |c;
        }
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

    method !render-border($gfx, @border) {
        my %border = $.css.border;
        my Numeric @width[4] = $!box.measurements(%border<border-width>);
        my @stroke = [
            @border[Top] - @width[Top]/2,
            @border[Right] - @width[Right]/2,
            @border[Bottom] + @width[Bottom]/2,
            @border[Left] + @width[Left]/2,
        ];
        my \w = @stroke[Right] - @stroke[Left];
        my \h = @stroke[Top] - @stroke[Bottom];

        if @width.unique == 1
        && %border<border-color>.map({($_//'').Str}).unique == 1
        && %border<border-style>.unique == 1 {
            # all 4 edges are the same. draw a simple rectangle
            with %border<border-color>[0] -> Color $_ {
                my \border-style = %border<border-style>[0];
                if @width[0] && border-style ne 'none' && .a != 0 {
                    my $width = @width[0];
                    $gfx.LineWidth = $width;
                    $gfx.StrokeAlpha = .a / 255;
                    $gfx.StrokeColor = color $_;
                    $gfx.DashPattern = self!dash-pattern( %border<border-style>[0], :$width );

                    $gfx.Rectangle(@stroke[Left], @stroke[Bottom], w, h);

                    $gfx.Stroke;
                }
            }
        }
        else {
            # edges differ. draw them separately
            for (Top, Right, Bottom, Left) -> \edge {
                given @width[edge] -> $width {
                    with %border<border-color>[edge] -> Color $_ {
                        my $border-style = %border<border-style>[edge];
                        if $width && $border-style ne 'none' && .a !=~= 0 {
                            $gfx.LineWidth = $width;
                            $gfx.StrokeAlpha = .a / 255;
                            $gfx.StrokeColor = color $_;
                            my Numeric \pos = @stroke[edge];
                            if edge ~~ Top|Bottom {
                                $gfx.DashPattern = self!dash-pattern: $border-style, :$width, :length(w);
                                $gfx.MoveTo( @stroke[Left], pos);
                                $gfx.LineTo( @stroke[Right], pos);
                            }
                            else {
                                $gfx.DashPattern = self!dash-pattern: $border-style, :$width, :length(h);
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
        my $width = $bg-image.width * Lengths::px;
        my $height = $bg-image.height * Lengths::px;
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

    #| Do basic styling, common to all box types (image, text, canvas)
    method style-box(PDF::Content $_) {
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

    method text-box-options (
        $?:
        PDF::Style::Font:D :font($box-font) = $!box.font,
        CSS::Properties :$css = $!box.css,
                                Numeric :$ref = 0,
    ) is export(:text-box-options) {
        my $kern = $css.font-kerning eq 'normal' || (
            $css.font-kerning eq 'auto' && $css.em <= 32
        );

        my $indent = $css.measure(:text-indent, :$ref);
        my $align = $css.text-align;
        my $font-size = $css.em;
        my $leading = $css.measure(:line-height) / $font-size;
        my PDF::Content::FontObj $font = $box-font.font-obj;

        # we currently support a vertical-align subset
        my $valign = do given $css.vertical-align {
            when 'middle' { 'center' }
            when 'top'|'bottom' { $_ }
            default { 'top' };
        }
        my %opt = :baseline<top>, :$font, :$kern, :$font-size, :$leading, :$align, :$valign, :$indent;

        given $css.letter-spacing {
            %opt<CharSpacing> = $css.measure($_)
                unless $_ eq 'normal';
        }

        given $css.word-spacing {
            %opt<WordSpacing> = $css.measure($_) - $font.stringwidth(' ', $font-size)
                unless $_ eq 'normal';
        }

        given $css.white-space {
            when 'normal' {}
            when 'pre'|'pre-wrap'|'break-spaces' {
                %opt<verbatum> = True;
            }
            when 'pre-line' {
                %opt<verbatum> = True;
                %opt<squish> = True;
            }
        }

        %opt;
    }

    method setup-graphics(PDF::Content $_) {
        .FillColor = do with $.css.color { color $_ } else { gray(0.0) };
        .FillAlpha = .StrokeAlpha = $.css.opacity.Num;
    }

    method graphics(PDF::Content $_, &actions) {
        .graphics: {
            self.setup-graphics($_);
            &actions($_);
        }
    }
}
