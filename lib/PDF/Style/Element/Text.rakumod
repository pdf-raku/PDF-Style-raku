use v6;

use PDF::Style::Element;

class PDF::Style::Element::Text
    is PDF::Style::Element {

    use CSS::Box;
    use CSS::Properties;
    use PDF::Style::Font;

    use PDF::Content::Color :&color, :&gray;
    use PDF::Content::Text::Box;
    use PDF::Content::FontObj;
    has PDF::Content::Text::Box $.text;
    use PDF::Tags::Elem;

    method !text-box-options( :$font!, CSS::Properties :$css!, CSS::Box :$container ) {
        my $kern = $css.font-kerning eq 'normal' || (
            $css.font-kerning eq 'auto' && $css.em <= 32
        );

        my $indent = $css.measure(:text-indent, :ref($container.width));
        my $align = $css.text-align;
        my $font-size = $css.em;
        my $leading = $css.measure(:line-height) / $font-size;
        my PDF::Content::FontObj $face = $font.font-obj;

        # support a vertical-align subset
        my $valign = do given $css.vertical-align {
            when 'middle' { 'center' }
            when 'top'|'bottom' { $_ }
            default { 'top' };
        }
        my %opt = :baseline<top>, :font($face), :$kern, :$font-size, :$leading, :$align, :$valign, :$indent;

        given $css.letter-spacing {
            %opt<CharSpacing> = $css.measure($_)
                unless $_ eq 'normal';
        }

        given $css.word-spacing {
            %opt<WordSpacing> = $css.measure($_) - $face.stringwidth(' ', $font-size)
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

    #| create a child element. Positioning is relative to this object. CSS styles
    #| are inherited from this object.
    method place-element( Str:D :$text!,
                          CSS::Properties :$css!,
                          CSS::Box :$container!,
                          PDF::Tags::Elem :$tag,
        ) {

        my PDF::Style::Font $font = $container.font.setup($css);
        my %opt = self!text-box-options( :$font, :$css, :$container);
        my &build-content = sub (|c) {
            text => PDF::Content::Text::Box.new( :$text, |%opt, |c);
        };
        nextwith(:$css, :&build-content, :$container, :$tag);
    }

    method !set-font-color($gfx) {
        with $.css.color {
            $gfx.FillColor = color $_;
            $gfx.FillAlpha = .a / 255;
        }
        else {
            $gfx.FillColor = gray(0.0);
            $gfx.FillAlpha = 1.0;
        }
        $gfx.StrokeAlpha = 1.0;
    }

    method render-element($gfx) {
        with $!text -> \text {
            my $top = $.top - $.bottom;
            self!set-font-color($gfx);
            $gfx.print(text, :position[ :left(0), :$top]);
        }
    }

    method !div(CSS::Properties $css, Str $text) {
        my $style-att = $css
            ?? $.html-escape($css.write).fmt: ' style="%s"'
            !! '';
        '<div%s>%s</div>'.sprintf($style-att, $text);
    }

    method html {
        my $css = $.css;

        my $text = do with $!text {
            $.html-escape(.text);
        }
        else {
            ''
        }

        given $css.vertical-align -> $valign {
            unless $valign eq 'baseline' {
                # hah, we're verically aligning a div!
                # wrap content in sized div for vertical align to take affect
                my @size-props = <top left bottom right width height position>.grep: {$css.property-exists($_)};
                if @size-props {
                    my CSS::Properties:D $inner = $css.clone;
                    $css = CSS::Properties.copy($inner, :properties(@size-props));
                    $css.display = 'table';
                    $inner.delete: @size-props;
                    $inner.display = 'table-cell';
                    $text = self!div($inner, $text);
                }
            }
        }

        self!div($css, $text);
    }

}
