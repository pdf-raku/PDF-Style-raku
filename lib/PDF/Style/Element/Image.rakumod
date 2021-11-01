use v6;

use PDF::Style::Element :&css-width, :&css-height;

class PDF::Style::Element::Image
    is PDF::Style::Element {

    use CSS::Box;
    use CSS::Properties;
    use CSS::Units :Lengths;
    use PDF::Content;
    use PDF::Content::XObject;
    use PDF::Tags::Elem;

    our class ScaledImage {
        has PDF::Content::XObject $.xobject is required handles <width height data-uri>;
        has Numeric  $.x-scale is rw = Lengths::px;
        has Numeric  $.y-scale is rw = Lengths::px;
        method content-width  { self.width * self.x-scale }
        method content-height { self.height * self.y-scale }

        submethod TWEAK( CSS::Properties :$css!, :$width! is copy, :$height! is copy) {
            my \img-width = self.width
                || die "unable to determine image width";
            my \img-height = self.height
                || die "unable to determine image height";

            with $css.min-width {
                $width = $_ if !$width.defined || $width < $_;
            }

            with $css.min-height {
                $height = $_ if !$height.defined || $height < $_;
            }

            if $width {
                $!x-scale = $width / img-width;
                $!y-scale = $height
                    ?? $height / img-height
                    !! $!x-scale;
            }
            elsif $height {
                $!y-scale = $height / img-height;
                $!x-scale = $!y-scale;
            }
        }

        method render-element(PDF::Content $gfx) {
            my $width  = $.content-width;
            my $height = $.content-height;

            $gfx.do($.xobject, :$width, :$height);
        }

    }
    has ScaledImage $.image is required handles <render-element>;

    method place-element(
        Str :$image,
        PDF::Content::XObject :$xobject = PDF::Content::XObject.open($image),
        CSS::Properties :$css!,
        CSS::Box :$container!,
        PDF::Tags::Elem :$tag,
    ) {
        my $width = css-width($container, $css);
        my $height = css-height($container, $css);
        my &build-content = sub (|) {
            my ScaledImage $image .= new( :$xobject, :$css, :$width, :$height );
            :$image;
        }
        nextwith(:$css, :&build-content, :$container, :$tag);
    }

    method html {
        my $style = $.css.write;

        my $style-att = $style
            ?? $.html-escape($style).fmt: ' style="%s"'
            !! '';

        given $!image {
            '<img%s src="%s"/>'.sprintf($style-att, .data-uri);
        }
    }

}
