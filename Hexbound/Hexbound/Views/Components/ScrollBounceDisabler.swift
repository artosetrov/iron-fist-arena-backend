import SwiftUI

/// A transparent UIViewRepresentable that finds its nearest parent UIScrollView
/// and disables elastic bounce (overscroll). Place as `.background(ScrollBounceDisabler())`
/// inside the ScrollView's content to prevent the user from scrolling past the content edges.
///
/// Used in panoramic map views (DungeonMapView, CityMapView) to lock scrolling
/// exactly to the image boundaries with no visible empty space beyond edges.
struct ScrollBounceDisabler: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = ScrollBounceDisablerView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

/// Custom UIView that disables bounce on its parent UIScrollView
/// once it's added to the view hierarchy.
private class ScrollBounceDisablerView: UIView {
    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard window != nil else { return }
        disableBounceOnParentScrollView()
    }

    private func disableBounceOnParentScrollView() {
        var current: UIView? = superview
        while let view = current {
            if let scrollView = view as? UIScrollView {
                scrollView.bounces = false
                scrollView.alwaysBounceHorizontal = false
                scrollView.alwaysBounceVertical = false
                return
            }
            current = view.superview
        }
    }
}
