use v6;

use PDF::Style::Element;

class PDF::Style::Viewport
    is PDF::Style::Element {

    use HTML::Entity;

    method !setup-size {
        # todo: see https://www.w3.org/TR/css3-page/
        # @top-left-corner etc
        # page-break-before, page-break-after etc
        use PDF::Content::Page :PageSizes;
        use CSS::Declarations::Units;
        use CSS::Declarations::Box :Edges;
        my @length;
        my $orientation = 'portrait';

        my $box := self.box;

        for $box.css.size.list {
            when Numeric {
                @length.push: $_;
            }
            when 'portrait' | 'landscape' {
                $orientation = $_;
            }
            when 'auto' {
            }
            when PageSizes.enums{.uc}:exists {
                my Array $size = PageSizes.enums{.uc};
                @length = $size[2], $size[3];
            }
            default {
                warn "unhandled viewport 'size' {.perl}";
            }
        }

        my ($page-width, $page-height) = do if @length {
            @length[1] //= @length[0];
            @length;
        } else {
            ($box.width, $box.height);
        }

        ($page-height, $page-width) = ($page-width, $page-height)
            if $orientation eq 'landscape';

        my @padding = $box.widths($box.css.padding);
        my @border  = $box.widths($box.css.border-width);
        my @margin  = $box.widths($box.css.margin);
        my @box = $page-height, $page-width, 0, 0;
        @box[$_] -= @padding[$_] + @border[$_] + @margin[$_]
            for Top, Right;
        @box[$_] += @padding[$_] + @border[$_] + @margin[$_]
            for Bottom, Left;

        $box.Array = @box;
    }

    method TWEAK {
        self!setup-size;
    }

    method !setup-page($page) {
        $page.media-box = [0, 0, self.width("margin"), self.height("margin") ];
        # draw borders + background image
        self.render($page);
    }

    method add-page($pdf) {
        my \page = $pdf.add-page;
        self!setup-page(page);
        page;
    }

    multi method element( :$canvas!, |c) {
        use PDF::Style::Element::Canvas;
        PDF::Style::Element::Canvas.place-element( :$canvas, :parent-box(self.box), |c);
    }

    multi method element( :$image!, |c) {
        use PDF::Style::Element::Image;
        PDF::Style::Element::Image.place-element( :$image, :parent-box(self.box), |c);
    }

    multi method element( :$text!, |c) {
        use PDF::Style::Element::Text;
        PDF::Style::Element::Text.place-element( :$text, :parent-box(self.box), |c);
    }

    multi method element( |c) is default {
        PDF::Style::Element.place-element( :parent-box(self.box), |c);
    }

    method render-element($) { }

    method html-start {
        my $style = $.css.write;
        my $style-att = $style
            ?? encode-entities($style).fmt: ' style="%s"'
            !! '';
        '<div%s>'.sprintf($style-att);
    }

    method html-end { '</div>' }
}
