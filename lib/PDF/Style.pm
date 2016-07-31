use v6;

module PDF::Style {
    use CSS::Declarations::Units;
    sub pt($v) is export(:pt) {
        if $v ~~ Numeric {
            if $v {
                my $units = $v.?key // 'pt';
                my $scale = Units.enums{$units}
                or die "unknown units: $units";
                $v / $scale
            }
            else {
                0
            }
        }
        else {
            Nil
        }
    }

}
