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

    method place-element( Str:D :$text!,
                          CSS::Properties :$css!,
                          CSS::Box :$container!,
                          PDF::Tags::Elem :$tag,
        ) {

        my PDF::Style::Font $font = $container.font.setup($css);
        my Numeric $ref = $container.width;
        my %opt = self.text-box-options( :$font, :$css, :$ref);
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
