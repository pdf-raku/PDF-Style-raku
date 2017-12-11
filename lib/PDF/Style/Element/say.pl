    method say( Str:D $text!,
                CSS::Declarations :$css!,
                :$font!,
                |c,
        ) {
        my CSS::Declarations::Box $box .= new: :$font, :$css;
        my %opt = self!text-block-options( :$font, :$css);
        %opt<width> = $_ with $box.css-width;
        %opt<height> = $_ with $box.css-height;
        my $text-block = PDF::Content::Text::Block.new: :$text, |%opt, |c;
        my $width = %opt<width> // $text-block.width;
        my $height = %opt<height> // $text-block.height;
        my $left = $font.length($css.left) // 0;
        my $bottom = $font.length($css.bottom) // 0;
        my $em = $font.em;
        my $ex = $font.ex;
        self.new: :text($text-block), :$css, :$left, :$bottom, :$width, :$height, :$em, :$ex;
    }

