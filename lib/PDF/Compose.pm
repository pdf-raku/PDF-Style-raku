use v6;

use PDF::Compose::Pages;

class PDF::Compose {

    has PDF::Compose::Pages $!pages handles <page>;

    submethod BUILD(:$!pages = PDF::Compose::Pages.new ) {
    }
}

