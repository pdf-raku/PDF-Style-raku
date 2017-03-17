use v6;

use PDF::Style::Box;
use CSS::Declarations::Units;

class PDF::Style::Viewport
    is PDF::Style::Box {

    method !setup-size {
        # todo: see https://www.w3.org/TR/css3-page/
        # @top-left-corner etc
        # page-break-before, page-break-after etc
        use PDF::Content::Page :PageSizes;
        use CSS::Declarations::Box :Edges;
        my @length;
        my $orientation = 'portrait';

        for self.css.size.list {
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

        my @padding = self.widths($.css.padding);
        my @border  = self.widths($.css.border-width);
        my @margin  = self.widths($.css.margin);
        my @box = $page-height, $page-width, 0, 0;
        @box[$_] -= @padding[$_] + @border[$_] + @margin[$_]
            for Top, Right;
        @box[$_] += @padding[$_] + @border[$_] + @margin[$_]
            for Bottom, Left;

        self.Array = @box;
    }

    method TWEAK {
        self!setup-size;
    }

    #| class to use for creating child boxes
    method box-delegate {
        PDF::Style::Box;
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

    method html-start {
        self.html.subst( /:s '</div>' $/, '');
    }

    method html-end { '</div>' }
}
