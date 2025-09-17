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
  
  private let host: UIHostingController<Content>
  
  public init(title: CardTitle,
              rootView: Content,
              mapManager: TGCompatibleMapManager? = nil,
              initialPosition: TGCardPosition? = nil) {
    
    self.host = UIHostingController(rootView: rootView)
    
    super.init(title: title, mapManager: mapManager, initialPosition: mapManager != nil ? initialPosition : .extended)
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
