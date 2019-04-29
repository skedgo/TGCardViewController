//
//  TGPageCard.swift
//  TGCardViewController
//
//  Created by Kuan Lun Huang on 18/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

/// A page card lets users navigate between cards that are on the same
/// hierarchical level, where each card is managed by its own `TGCard`
/// subclass. Navigation between cards can be controlled programatically
/// (through the `TGPageCardView`'s methods) by your app or directly
/// by the user using gestures.
///
/// Think of this class as an equivalent of `UIPageViewController`, but
/// for cards.
///
/// This class is generally used as-is, but can also be subclassed.
open class TGPageCard: TGCard {
  
  public override weak var controller: TGCardViewController? {
    didSet {
      cards.forEach {
        $0.controller = controller
      }
    }
  }
  
  // Styling
  
  public override var backgroundColor: UIColor? {
    didSet { headerView?.applyStyling(for: self) }
  }

  public override var grabHandleColor: UIColor? {
    didSet { headerView?.applyStyling(for: self) }
  }
  
  public override var titleFont: UIFont? {
    didSet { headerView?.applyStyling(for: self) }
  }
  
  public override var titleTextColor: UIColor? {
    didSet { headerView?.applyStyling(for: self) }
  }

  public override var subtitleFont: UIFont? {
    didSet { headerView?.applyStyling(for: self) }
  }
  
  public override var subtitleTextColor: UIColor? {
    didSet { headerView?.applyStyling(for: self) }
  }

  
  /// The cards displayed by the page card
  public let cards: [TGCard]
  
  let initialPageIndex: Int
  
  public var currentPageIndex: Int {
    guard let pageCard = cardView as? TGPageCardView else { return initialPageIndex }
    return pageCard.currentPage
  }
  
  fileprivate var currentCard: TGCard {
    return cards[currentPageIndex]
  }
  
  fileprivate var previousAppearedCard: TGCard?
    
  fileprivate var headerView: TGPageHeaderView?
  
  fileprivate weak var headerPageControl: UIPageControl?
  
  /// Customisation for the header's right button
  /// 
  /// `title` will be used as the button's title and `onPress` will be
  /// triggered when the button is pressed with the current page provided
  /// as the single parameter.
  ///
  /// - note: If this is not set the default "next" button will be used.
  /// - warning: This will not get restored as part of state restoration.
  ///     Make sure to do so manually.
  public var headerRightAction: (title: String, onPress: (Int) -> Void)?
  
  /// Customisation of the header's accessory view
  ///
  /// - note: If this is not set a default `UIPageControl will be used
  ///         indicating the current page.
  public var headerAccessoryView: UIView?
  
  /// Initialise a new page card.
  ///
  /// - Parameters:
  ///   - cards: these are the child cards that will be displayed by the page card as pages.
  ///   - initialPage: the index of the first child card (page) to display when the page card is pushed.
  ///   - initialPosition: Position of the card when first pushed. Defaults to `.peaking`
  public init(cards: [TGCard], initialPage: Int = 0, initialPosition: TGCardPosition = .peaking) {
    assert(TGPageCard.allCardsHaveMapManagers(in: cards), "TGCardVC doesn't yet properly handle " +
      "page cards where some cards don't have map managers. It won't crash but will experience " +
      "unexpected behaviour, such as the 'extended' mode not getting enforced or getting stuck " +
      "in 'extended' mode.")
    
    self.cards = cards
    self.initialPageIndex = min(initialPage, cards.count - 1)

    // TGPageCard itself doesn't have a map manager. Instead, it passes through
    // the manager that handles the map view for the current card. This is
    // set on intialising and then updated whenever we scroll.
    let mapManager = cards[initialPage].mapManager
    
    super.init(title: .none, mapManager: mapManager, initialPosition: initialPosition)
  }
  
  public required init?(coder: NSCoder) {
    guard let cards = coder.decodeObject(forKey: "cards") as? [TGCard] else {
      return nil
    }
    let initialPage = coder.decodeInteger(forKey: "initialPageIndex")
    self.headerAccessoryView = coder.decodeView(forKey: "headerAccessoryView")
    
    assert(TGPageCard.allCardsHaveMapManagers(in: cards), "TGCardVC doesn't yet properly handle " +
      "page cards where some cards don't have map managers. It won't crash but will experience " +
      "unexpected behaviour, such as the 'extended' mode not getting enforced or getting stuck " +
      "in 'extended' mode.")
    
    self.cards = cards
    self.initialPageIndex = min(initialPage, cards.count - 1)

    // TGPageCard itself doesn't have a map manager. Instead, it passes through
    // the manager that handles the map view for the current card. This is
    // set on intialising and then updated whenever we scroll.
    let mapManager = cards[initialPage].mapManager
    
    super.init(title: .none, mapManager: mapManager, initialPosition: .peaking)
  }
  
  open override func encode(with aCoder: NSCoder) {
    aCoder.encode(currentPageIndex, forKey: "initialPageIndex")
    aCoder.encode(cards, forKey: "cards")
    aCoder.encode(view: headerAccessoryView, forKey: "headerAccessoryView")
  }
  
  fileprivate static func allCardsHaveMapManagers(in cards: [TGCard]) -> Bool {
    for card in cards where card.mapManager == nil {
      return false
    }
    return true
  }
  
  open override func buildCardView() -> TGCardView {
    let view = TGPageCardView.instantiate()
    view.configure(with: self)
    view.delegate = self
    
    // reset the header, too, so that it's not left
    // in an outdated state
    headerView = nil
    
    // also need to reset the map manager, too
    mapManager = cards[initialPageIndex].mapManager
    
    return view
  }
  
  open override func buildHeaderView() -> TGHeaderView? {
    if let header = headerView {
      return header
    }
    
    let view = TGPageHeaderView.instantiate()
    view.applyStyling(for: self)
    
    if let accessory = headerAccessoryView {
      view.accessoryView = accessory
    } else {
      let pageControl = UIPageControl()
      pageControl.currentPage = initialPageIndex
      pageControl.numberOfPages = cards.count
      pageControl.pageIndicatorTintColor = subtitleTextColor ?? .lightGray
      pageControl.currentPageIndicatorTintColor = grabHandleColor ?? .blue
      pageControl.addTarget(self, action: #selector(headerPageControlChanged(sender:)), for: .valueChanged)
      self.headerPageControl = pageControl
      view.accessoryView = pageControl
    }
    
    let card = cards[initialPageIndex]
    headerView = view
    updateHeader(for: card, atIndex: initialPageIndex)
    return view
  }

  // MARK: - Header actions
  
  fileprivate func update(forCardAtIndex index: Int, animated: Bool = false) {
    guard index < cards.count else {
      assertionFailure()
      return
    }
    
    let card = cards[index]
    
    mapManager = card.mapManager
    updateHeader(for: card, atIndex: index, animated: animated)
    
    didMoveToPage(index: index)
  }
  
  fileprivate func updateHeader(for card: TGCard, atIndex index: Int, animated: Bool = false) {
    guard let headerView = headerView else {
      preconditionFailure()
    }
    
    headerPageControl?.currentPage = index

    if let rightAction = headerRightAction {
      headerView.rightButton?.setImage(nil, for: .normal)
      headerView.rightButton?.setTitle(rightAction.title, for: .normal)
      headerView.accessibilityLabel = rightAction.title
      headerView.rightAction = { [unowned self] in
        rightAction.onPress(self.currentPageIndex)
      }
      
    } else {
      headerView.rightButton?.setImage(TGCardStyleKit.imageOfHeaderNextIcon(), for: .normal)
      headerView.rightButton?.setTitle(nil, for: .normal)
      headerView.rightButton?.accessibilityLabel = NSLocalizedString("Next", comment: "Next button accessory title")
      
      if index + 1 < cards.count {
        headerView.rightAction = { [unowned self] in
          self.moveForward()
        }
      } else {
        headerView.rightAction = nil
      }
    }
    
    headerView.setNeedsLayout()
    
    UIView.animate(withDuration: animated ? 0.25 : 0) {
      headerView.layoutIfNeeded()
    }
  }
  
  @objc
  func headerPageControlChanged(sender: UIPageControl) {
    guard sender.currentPage != currentPageIndex else { return }
    
    move(to: sender.currentPage)
  }
  
  
  // MARK: - Navigation
  
  /// Navigates to the next card, animated
  public func moveForward() {
    guard let pageCard = cardView as? TGPageCardView else { return  }
    pageCard.moveForward()
  }
  
  /// Navigates to the previous card, animated
  public func moveBackward() {
    guard let pageCard = cardView as? TGPageCardView else { return  }
    pageCard.moveBackward()
  }
  
  /// Navigates to the card at the provided index, animated
  ///
  /// - Parameter page: Index of the card
  public func move(to page: Int) {
    guard let pageCard = cardView as? TGPageCardView else { return  }
    pageCard.move(to: page)
  }
  
  /// Called whenever the current page has changed
  ///
  /// - Parameter index: New page index
  open func didMoveToPage(index: Int) {
    // nothing to do
  }
  
  @objc
  func dismissTapped(sender: Any) {
    controller?.pop()
  }
  
  
  // MARK: - Card life cycle
  
  open override func willAppear(animated: Bool) {
    currentCard.willAppear(animated: animated)
  }
  
  open override func didAppear(animated: Bool) {
    previousAppearedCard = currentCard
    currentCard.didAppear(animated: animated)
  }
  
  open override func willDisappear(animated: Bool) {
    currentCard.willDisappear(animated: animated)
  }
  
  open override func didDisappear(animated: Bool) {
    currentCard.didDisappear(animated: animated)
    previousAppearedCard = nil
  }
  
}

extension TGPageCard: TGPageCardViewDelegate {
  
  func didChangeCurrentPage(to index: Int, animated: Bool) {
    update(forCardAtIndex: index, animated: animated)
    
    let previous = previousAppearedCard
    let current  = currentCard
    
    previous?.willDisappear(animated: false) // no time to animate
    current.willAppear(animated: false) // no time to animate
    previousAppearedCard = current
    current.didAppear(animated: animated)
    previous?.didDisappear(animated: animated)

    if let previousIndex = cards.firstIndex(where: { $0 === previous }),
      let pageCard = cardView as? TGPageCardView {
      let previousCardView = pageCard.cardViews[previousIndex]
      delegate?.contentScrollViewDidChange(old: previousCardView.contentScrollView, for: self)
    } else {
      delegate?.contentScrollViewDidChange(old: nil, for: self)
    }
  }
  
}
