import SwiftUI

// MARK: - GSAP-style easing curves
//
// SwiftUI's built-in easings (.easeOut, .spring) don't match GSAP's signature
// feel. These reproduce GSAP's most common eases as SwiftUI timing curves so
// the landing page's choreography (staggered reveals, overshoot, snappy
// settles) feels the way GSAP timelines feel on the web.

extension Animation {
    /// GSAP's default "power2.out" — fast start, smooth decelerating tail.
    static func gsapPower2Out(duration: Double = 0.6) -> Animation {
        .timingCurve(0.16, 1, 0.3, 1, duration: duration)
    }

    /// GSAP's "power3.out" — steeper deceleration, snappier than power2.
    static func gsapPower3Out(duration: Double = 0.55) -> Animation {
        .timingCurve(0.22, 1, 0.36, 1, duration: duration)
    }

    /// GSAP's "back.out(1.7)" — overshoots slightly then settles, the
    /// classic "pop" GSAP is known for on cards/buttons.
    static func gsapBackOut(duration: Double = 0.6) -> Animation {
        .timingCurve(0.34, 1.56, 0.64, 1, duration: duration)
    }

    /// GSAP's "expo.out" — very fast start, long smooth tail. Good for big
    /// hero elements sliding/fading into place.
    static func gsapExpoOut(duration: Double = 0.8) -> Animation {
        .timingCurve(0.16, 1, 0.3, 1, duration: duration)
    }
}

/// Drives a GSAP-timeline-style staggered sequence: each item in a list gets
/// its own delay offset, mirroring `gsap.to(".item", { stagger: 0.08 })`.
struct Stagger {
    static func delay(index: Int, base: Double = 0.08, initialDelay: Double = 0) -> Double {
        initialDelay + Double(index) * base
    }
}
