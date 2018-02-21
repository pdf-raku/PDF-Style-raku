use v6;

use PDF::Style::Element;

class PDF::Style::Element::Text
    is PDF::Style::Element {

    use HTML::Entity;
    use CSS::Declarations;
    use PDF::Content::Text::Block;
    has PDF::Content::Text::Block $.text;

    method !text-block-options( :$font!, :$css! ) {
        my $kern = $css.font-kerning eq 'normal' || (
            $css.font-kerning eq 'auto' && $font.em <= 32
        );

        my $align = $css.text-align;
        my $font-size = $font.em;
        my $leading = $font.line-height / $font-size;
        my $face = $font.font-obj;

        # support a vertical-align subset
        my $valign = do given $css.vertical-align {
            when 'middle' { 'center' }
            when 'top'|'bottom' { $_ }
            default { 'top' };
        }
        my %opt = :baseline<top>, :font($face), :$kern, :$font-size, :$leading, :$align, :$valign;

        %opt<CharSpacing> = do given $css.letter-spacing {
            when .type eq 'num'     { $_ * $font-size }
            when .type eq 'percent' { $_ * $font-size / 100 }
            when 'normal' { 0.0 }
            default       { $font.length($_) }
        }

        %opt<WordSpacing> = do given $css.word-spacing {
            when 'normal' { 0.0 }
            default       { $font.length($_) - $face.stringwidth(' ', $font-size) }
        }
        %opt;
    }

    #| create a child element. Positioning is relative to this object. CSS styles
    #| are inherited from this object.
    method place-element( Str:D :$text!,
                    CSS::Declarations :$css!,
                    :$container!,
        ) {

        my $font = $container.font.setup($css);
        my %opt = self!text-block-options( :$font, :$css);
        my &build-content = sub (|c) {text => PDF::Content::Text::Block.new( :$text, |%opt, |c) };
        nextwith(:$css, :&build-content, :$container);
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

    method render-element($gfx) {
        with $!text -> \text {
            my $top = $.top - $.bottom;
            self!set-font-color($gfx);
            $gfx.print(text, :position[ :left(0), :$top]);
        }
    }

    method html {
        my $css = $.css.clone;
        $css.delete('vertical-align'); # we'll deal with this later
        my $style = $css.write;

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

        my $style-att = $style
            ?? encode-entities($style).fmt: ' style="%s"'
            !! '';
        '<div%s>%s</div>'.sprintf($style-att, $text);
    }

}
