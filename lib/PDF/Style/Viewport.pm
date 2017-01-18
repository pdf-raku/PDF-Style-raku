use v6;

use PDF::Style::Box :Edges;
use CSS::Declarations::Units;

class PDF::Style::Viewport
    is PDF::Style::Box {

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
