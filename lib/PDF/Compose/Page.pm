use v6;

class PDF::Compose::Page {

    has Str $!content = '';
    has Str $!current-font = "Helvetica";

    method text( $text, Hash :$style = {}, Bool :$dry = False, Str :$enc = 'latin1') {

        die "can't handle encoding: $enc"
            unless $enc eq 'latin1';

        die "can't handle :dry == True"
            if $dry;

    }
}
