//
//  TGHostingCard.swift
//
//
//  Created by Adrian Schönig on 21/4/21.
//


import SwiftUI

/// A hosting card can be used to use a SwiftUI `View` as the card's content.
///
/// - warning: The view should **not** be scrolling, i.e., don't use this with a `ScrollView`,
///   a `List`, a `Form` or similar. It should rather be a `VStack` or similar as the view will be
///   embedded in a `UIScrollView` when being added to the card.
@available(iOS 13.0, *)
open class TGHostingCard<Content>: TGCard where Content: View {
  
  private let host: UIHostingController<AnyView>
  private let relay: _TGSizeRelay
  
  public init(title: CardTitle,
              rootView: Content,
              mapManager: TGCompatibleMapManager? = nil,
              initialPosition: TGCardPosition? = nil) {
    
    let relay = _TGSizeRelay()
    let observedRoot = rootView._tgOnSizeChange { [weak relay] in
      relay?.onSize?($0)
    }
    self.host = UIHostingController(rootView: AnyView(observedRoot))
    self.relay = relay

    super.init(title: title, mapManager: mapManager, initialPosition: mapManager != nil ? initialPosition : .extended)

    // After init, connect size changes to intrinsic invalidation so Auto Layout
    // updates content height. UIHostingController doesn't manage to reliably
    // do that itself, but nudging it this way does the trick.
    relay.onSize = { [weak host = self.host] size in
      guard let view = host?.view else { return }
      view.invalidateIntrinsicContentSize()
      view.setNeedsLayout()
    }
  }
  
  open func didBuild(scrollView: UIScrollView) {
  }
  
  open func didBuild(scrollView: UIScrollView, cardView: TGCardView) {
  }
  
  // MARK: - Constructing views
  
  open override func buildCardView() -> TGCardView? {
    let view = TGScrollCardView.instantiate(extended: title.isExtended)
    
    let scroller = UIScrollView(frame: .zero)
    view.configure(scroller, with: self)

    host.beginAppearanceTransition(true, animated: false)
    host.view.translatesAutoresizingMaskIntoConstraints = false
    host.view.backgroundColor = .clear
    scroller.addSubview(host.view)

    NSLayoutConstraint.activate([
      host.view.leadingAnchor.constraint(equalTo: scroller.contentLayoutGuide.leadingAnchor),
      host.view.topAnchor.constraint(equalTo: scroller.contentLayoutGuide.topAnchor),
      host.view.trailingAnchor.constraint(equalTo: scroller.contentLayoutGuide.trailingAnchor),
      host.view.bottomAnchor.constraint(equalTo: scroller.contentLayoutGuide.bottomAnchor),
      host.view.widthAnchor.constraint(equalTo: scroller.frameLayoutGuide.widthAnchor),
    ])
    host.endAppearanceTransition()
    
    return view
  }
  
  override public final func didBuild(cardView: TGCardView?, headerView: TGHeaderView?) {
    
    defer { super.didBuild(cardView: cardView, headerView: headerView) }
    
    guard let cardView, let scrollView = (cardView as? TGScrollCardView)?.embeddedScrollView else {
      preconditionFailure()
    }
    
    didBuild(scrollView: scrollView)
    didBuild(scrollView: scrollView, cardView: cardView)
  }
  
}


// MARK: - SwiftUI size reporting helper

private struct _TGSizeKey: PreferenceKey {
  static var defaultValue: CGSize = .zero
  static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
    value = nextValue()
  }
}

private struct _TGSizeReader: ViewModifier {
  let onChange: (CGSize) -> Void
  func body(content: Content) -> some View {
    content
      .background(
        GeometryReader { proxy in
          Color.clear
            .preference(key: _TGSizeKey.self, value: proxy.size)
            .onPreferenceChange(_TGSizeKey.self, perform: onChange)
        }
      )
  }
}

private extension View {
  func _tgOnSizeChange(_ perform: @escaping (CGSize) -> Void) -> some View {
    modifier(_TGSizeReader(onChange: perform))
  }
}

private final class _TGSizeRelay {
  var onSize: ((CGSize) -> Void)?
}

