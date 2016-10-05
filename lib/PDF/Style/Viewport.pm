use v6;

use PDF::Style::Box :Edges;
use CSS::Declarations::Units;

class PDF::Style::Viewport
    is PDF::Style::Box {

    method setup-page($page) {
        $page.media-box = [0, 0, self.width, self.height ];
        # draw borders + background image
        self.render($page);
    }

    method add-page($pdf) {
        my \page = $pdf.add-page;
        self.setup-page(page);
        page;
    }

    method html-start {
        use HTML::Entity;
        my $css = $.css.clone;
        $css.width = :pt(self.width);
        $css.height = :pt(self.height);
        $css.position = :keyw<relative>;
        my $style = encode-entities($css.write);
        my $text = do with $.content {
            encode-entities(.text);
        }
        else {
            ''
        }
        sprintf '<div style="%s">%s', $style, $text;
    }

    method html-end { '</div>' }
}
