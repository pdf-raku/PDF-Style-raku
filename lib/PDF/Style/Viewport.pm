use v6;

use PDF::Style::Box;
use CSS::Declarations::Units;

class PDF::Style::Viewport
    is PDF::Style::Box {

    method !setup-size {
        use PDF::Content::Page :PageSizes;
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

        if @length {
            @length[1] //= @length[0];
            (self.width, self.height) = @length;
        }

        (self.height, self.width) = (self.width, self.height)
            if $orientation eq 'landscape';
    }

    method TWEAK {
        self!setup-size;
        # todo: see https://www.w3.org/TR/css3-page/
        # @top-left-corner etc
        # page-break-before, page-break-after etc
    }

    method !setup-page($page) {
        $page.media-box = [0, 0, self.width, self.height ];
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
