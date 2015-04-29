use v6;

use PDF::Compose::Rendering::Text::Line;
use PDF::Compose::Rendering::Text::Atom;

class PDF::Compose::Rendering::Text::Block {
    has Numeric $.line-height;       #| e.g. line-height: 110%  ==>  1.1
    has $.width;
    has $.height;
    has @.lines;
    has @.overflow is rw;

    method actual-width  { @!lines.max({ .actual-width }); }
    method actual-height { @!lines.sum({ .actual-height * ($.line-height || 1) }); }

    submethod BUILD(         :@atoms is copy,
                     Numeric :$word-spacing!,
                     Numeric :$!line-height!,
                     Numeric :$!width?,      #| optional constraint
                     Numeric :$!height?,     #| optional constraint
        ) {

        @!lines;

        while @atoms {

            my $line = PDF::Compose::Rendering::Text::Line.new( :$word-spacing );
            my $line-width = 0.0;

            while @atoms {
                my $kern = @atoms[0].kern;
                my $word-width = @atoms[0].width;
                if $line.atoms && ! $kern {
                    # assume this is a word
                    $kern = $word-spacing;
                    last if $!width && $line-width + $word-width + $kern > $!width;
                }
                my $atom = @atoms.shift;
                $atom.kern = $kern;
                $line.atoms.push( $atom );
                $line-width += $word-width + $kern;
            }

            @!lines.push( $line )
                if +$line.atoms;

            last if $!height && @!lines * $!line-height > $!height;
        }

        @!overflow = @atoms;
    }
}
