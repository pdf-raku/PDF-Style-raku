use v6;

use PDF::Style::Element;

class PDF::Style::Body
    is PDF::Style::Element {

    use PDF::Style::Element::Image;
    use PDF::Style::Font;
    use CSS::Box :Edges;
    use PDF::Content::Canvas;
    has PDF::Style::Element @.elements;
    use CSS::PageBox;
    use CSS::Units :pt;
    use CSS::Stylesheet;
    use CSS::Font::Descriptor;
    use URI;

    submethod TWEAK(:$gfx, CSS::Font::Descriptor :@font-face, URI() :$base-url, |c) {
        my %opt;
        with $gfx {
            %opt<width>  = %opt<viewport-width>  = 0pt + .width;
            %opt<height> = %opt<viewport-height> = 0pt + .height;
        }
        # replace regular box with a page box.
        my $css  = self.box.css;
        my PDF::Style::Font $font = self.box.font;
        $font.base-url = $_ with $base-url;
        $font.font-face.append: @font-face;
        self.box = CSS::PageBox.new: :$css, :$font, |%opt, |c;
    }

    #| decorate the background of a PDF page, xobject, or pattern that's acting as a body
    method decorate(PDF::Content::Canvas $_, :$resize) {
        my $gfx = .gfx;
        self.TWEAK(:$gfx) if $resize;
        (.can('BBox') ?? .BBox !! .media-box) = [0, 0, self.width("margin"), self.height("margin") ];
        # draw borders + background image
        .render($gfx, .left, .bottom) with self;
        $_;
    }

    method !make-image(PDF::Content::XObject $xobject!) {
        my \image  = PDF::Style::Element::Image::Content.new: :image($xobject);
        my $height = self.box.css-height($.css);

        if self.box.css-width($.css) -> $width {
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
        my $container = self.box;
        sub length($v) { $container.font.length($v) }
        my $top = length($css.top) // 0;
        my $bottom = length($css.bottom) // 0;
        my $left   = length($css.left) // 0;
        my $right  = length($css.right) // 0;

        my $em = $container.font.em;
        my $ex = $container.font.ex;
        my $vw = $container.viewport-width;
        my $vh = $container.viewport-heigth;
        my $content-width = $xobject.width;
        my $content-height = $xobject.height;
        my $image = self!make-image($xobject);
        my $width = $image.content-width;
        my $height = $image.content-height;
        self.Array = [$top + $height + $bottom,
                      $left + $width + $right,
                      0, 0];
        my \pdf-top = self.height - $top;
        my \elem = PDF::Style::Element::Image.new: :$css, :$left, :top(pdf-top), :$width, :$height, :$em, :$ex, :$image, :$vw, :$vh;

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

    proto method element(|c) {
        @!elements.push: {*};
        @!elements.tail;
    }

    # compute style from :$tag and :$css arguments
    method !args(*%o) {
        %o<container> //= self.box;

        with %o<tag> {
            with .style -> $tag-css {
                with %o<css> -> $css {
                    %o<css> = CSS::Stylesheet::merge-properties [$tag-css, $css];
                }
                else {
                    %o<css> = $tag-css;
                }
            }
        }

        %o;
    }

    multi method element( :$html-canvas!, |c) {
        require PDF::Style::Element::HTMLCanvas;
        PDF::Style::Element::HTMLCanvas.place-element: :$html-canvas, |self!args(|c);
    }

    multi method element( :$image!, |c) {
        PDF::Style::Element::Image.place-element: :$image, |self!args(|c);
    }

    multi method element( :$xobject!, |c) {
        PDF::Style::Element::Image.place-element: :$xobject, |self!args(|c);
    }

    multi method element( :$text!, |c) {
        require PDF::Style::Element::Text;
        PDF::Style::Element::Text.place-element: :$text, |self!args(|c);
    }

    multi method element( |c) is default {
        PDF::Style::Element.place-element: |self!args(|c);
    }

    method render-element($) { }

    method html-start {
        my $style = $.css.write;
        my $style-att = $style
            ?? $.html-escape($style).fmt: ' style="%s"'
            !! '';
        '<body%s>'.sprintf($style-att);
    }

    method html-end { '</body>' }

    method html {
        [~] $.html-start, @!elements>>.html.Slip, $.html-end;
    }
}
