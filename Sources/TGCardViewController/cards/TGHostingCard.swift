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
  
  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: - Constructing views
  
  open override func buildCardView() -> TGCardView? {
    let view = TGScrollCardView.instantiate()
    
    host.beginAppearanceTransition(true, animated: false)
    
    let scroller = UIScrollView()
    scroller.translatesAutoresizingMaskIntoConstraints = false

    host.view.translatesAutoresizingMaskIntoConstraints = false
    scroller.addSubview(host.view)
    NSLayoutConstraint.activate([
      host.view.leadingAnchor.constraint(equalTo: scroller.leadingAnchor),
      host.view.topAnchor.constraint(equalTo: scroller.topAnchor),
      host.view.trailingAnchor.constraint(equalTo: scroller.trailingAnchor),
      host.view.bottomAnchor.constraint(equalTo: scroller.bottomAnchor),
    ])
    view.configure(scroller, with: self)
    
    host.view.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
    
    host.endAppearanceTransition()
    return view
  }
  
}
