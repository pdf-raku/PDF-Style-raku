use v6;

class PDF::Style {
    use CSS::Properties::Units;

    method element(|c) {
        require PDF::Style::Viewport;
        state $vp //= PDF::Style::Viewport.new: :width(1684), :height(2381);
        $vp.element(|c);
    }
}
