use v6;

use PDF::Style::Element;

class PDF::Style::Viewport
    is PDF::Style::Element {

    use HTML::Entity;
    use PDF::Style::Element::Image;
    use CSS::Declarations::Box :Edges;

    method !padding-box($right, $bottom, $left, $top) {
        my $box = self.box;
        my @padding = $box.widths($box.css.padding);
        my @border  = $box.widths($box.css.border-width);
        my @margin  = $box.widths($box.css.margin);
        my @box = $top, $left, $bottom, $right;
        @box[$_] -= @padding[$_] + @border[$_] + @margin[$_]
            for Top, Right;
        @box[$_] += @padding[$_] + @border[$_] + @margin[$_]
            for Bottom, Left;
        @box;
    }

    method !setup-size {
        # todo: see https://www.w3.org/TR/css3-page/
        # @top-left-corner etc
        # page-break-before, page-break-after etc
        use PDF::Content::Page :PageSizes;
        use CSS::Declarations::Units;
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
            (self.width, self.height);
        }

        ($page-height, $page-width) = ($page-width, $page-height)
            if $orientation eq 'landscape';

        $box.Array = self!padding-box(0, 0, $page-width, $page-height);
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

    method !make-image(PDF::Content::XObject $xobject!) {
        my $width  = self.box.css-width($.css);
        my $height = self.box.css-height($.css);
        my \image  = PDF::Style::Element::Image::Content.new: :image($xobject);
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
        else {
            image.x-scale = 1.0;
            image.y-scale = 1.0;
        }
        image;
    }

    #| resize to accomodate content
    method !auto-fit(PDF::Content::XObject $xobject) {
        my $css = self.css;
        my $parent-box = self.box;
        sub length($v) { $parent-box.font.length($v) }
        my $top = length($css.top) // 0;
        my $bottom = length($css.bottom) // 0;
        my $left   = length($css.left) // 0;
        my $right  = length($css.right) // 0;

        my $em = $parent-box.font.em;
        my $ex = $parent-box.font.ex;
        my $content-width = $xobject.width;
        my $content-height = $xobject.height;
        my $image = self!make-image($xobject);
        my $width = $image.content-width;
        my $height = $image.content-height;
        self.Array = [$top + $height + $bottom,
                      $left + $width + $right,
                      0, 0];
         my \pdf-top = self.height - $top;
        my \elem = PDF::Style::Element::Image.new: :$css, :$left, :top(pdf-top), :$width, :$height, :$em, :$ex, :$image;

        elem;
    }

    method import-page($page-in, $pdf-out, |c) {
        my $xobject = $page-in.to-xobject;
        my $body = self!auto-fit($xobject);

        my $outer = self.box.margin;

        my \page = $pdf-out.add-page;
        page.media-box = [$outer[Left], $outer[Bottom], $outer[Right], $outer[Top]];
        $body.render(page);
    }

    multi method element( :$canvas!, |c) {
        use PDF::Style::Element::Canvas;
        PDF::Style::Element::Canvas.place-element( :$canvas, :parent-box(self.box), |c);
    }

    multi method element( :$image!, |c) {
        PDF::Style::Element::Image.place-element( :$image, :parent-box(self.box), |c);
    }

    multi method element( :$xobject!, |c) {
        PDF::Style::Element::Image.place-element( :$xobject, :parent-box(self.box), |c);
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
