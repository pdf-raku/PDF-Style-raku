use v6;

module PDF::Style {
    use CSS::Declarations::Units;
    sub pt($_, Numeric :$em = 12, Numeric :$ex = $em * 3/4) is export(:pt) {
        when Numeric {
            (if $_ {
                    my $units = .?key // 'pt';
                    my $scale = do given $units {
                        when 'em' { $em }
                        when 'ex' { $ex }
                        when 'percent' { 0 }
                        default { Units.enums{$units} }
                    } // die "unknown units: $units";
                    (.Num * $scale).Num;
                }
             else {
                 0
             }) does CSS::Declarations::Units::Keyed["pt"];
        }
        default { Nil }
    }

}
