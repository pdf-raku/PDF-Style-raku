use v6;

module PDF::Style {
    use CSS::Declarations::Units;
    sub pt($v, Numeric :$em, Numeric :$ex) is export(:pt) {
        if $v ~~ Numeric {
            (if $v {
                my $units = $v.?key // 'pt';
                my $scale = do given $units {
                    when 'em' { $em }
                    when 'ex' { $ex }
                    default { Units.enums{$units} }
                } or die "unknown units: $units";
                ($v / $scale).Num
            }
            else {
                0
            }) does CSS::Declarations::Units::Keyed["pt"];
        }
        else {
            Nil
        }
    }

}
