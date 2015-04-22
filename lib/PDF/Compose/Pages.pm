use v6;

use PDF::Compose::Page;

class PDF::Compose::Pages {

    has PDF::Compose::Page @.pages;

    submethod BUILD(:@!pages = ()) {
    }

    method page(Int $page-num where $_ > 0) {

        # vivify a new last page
        @.pages.push: PDF::Compose::Page.new
            if $page-num == +@!pages + 1;

        die "page number $page-num out of range 1 .. {+@!pages}"
            unless $page-num <= +@!pages;

        $.pages[ $page-num - 1]
    }

}

