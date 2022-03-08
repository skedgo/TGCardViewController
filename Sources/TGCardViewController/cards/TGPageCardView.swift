//
//  TGPageCardView.swift
//  TGCardViewController
//
//  Created by Kuan Lun Huang on 18/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

protocol TGPageCardViewDelegate: AnyObject {
  
  func didChangeCurrentPage(to index: Int, animated: Bool)
  
}

class TGPageCardView: TGCardView {
  
  private enum Constants {
    static let animationDuration: Double = 0.4
    static let spaceBetweenCards: CGFloat = 5
  }
  
  @IBOutlet weak var pager: UIScrollView!
  
  @IBOutlet weak var contentView: UIView!

  @IBOutlet weak var pagerTrailingConstant: NSLayoutConstraint!
  
  private var lastHorizontalOffset: CGFloat = 0
  
  private var visiblePageLefty: Int = 0
  
  private var visiblePageLogical: Int = 0

  weak var delegate: TGPageCardViewDelegate?
  
  /// The card views, ordered as provided, i.e., logically first one first; not by how it appears.
  var cardViews: [TGCardView] {
    (contentView.subviews as? [TGCardView]) ?? []
  }
  
  private var pageCount: Int {
    cardViews.count
  }
  
  private func cardView(index: Int) -> TGCardView? {
    let cardViews = self.cardViews
    guard index >= 0, index <= cardViews.count else { return nil }
    return cardViews[index]
  }
  
  private var topView: UIView?
  override var preferredView: UIView? {
    topView ?? self
  }
  
  override var grabHandles: [TGGrabHandleView] {
    cardViews.compactMap(\.grabHandle)
  }
  
  override var headerHeight: CGFloat {
    guard !contentView.subviews.isEmpty else { return 0 }
    
    var currentContent: UIView?
    
    for aContent in contentView.subviews {
      if aContent.frame.contains(pager.contentOffset) {
        currentContent = aContent
      }
    }
    
    if let cardView = currentContent as? TGCardView {
      return cardView.headerHeight
    }
    
    return 0
  }
  
  override var contentScrollView: UIScrollView? {
    get {
      let logical = currentLogicalIndex()
      return cardView(index: logical)?.contentScrollView
    }
    set {
      assertionFailure("Don't set this on paging a PageCard. Was set to \(String(describing: newValue)).")
    }
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    
    // remove corner as we want each card to show its own corners
    layer.mask = nil
    
    move(to: visiblePageLogical, animated: false)
  }
  
  // MARK: - New instance
  
  static func instantiate() -> TGPageCardView {
    guard
      let view = TGCardViewController.bundle.loadNibNamed("TGPageCardView", owner: nil, options: nil)!.first as? TGPageCardView
      else { preconditionFailure() }
    return view
    
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    pagerTrailingConstant.constant = Constants.spaceBetweenCards
  }
  
  // MARK: - Full card view configuration
  
  func configure(with pageCard: TGPageCard) {
    // TODO: This does a lot of work by building all the child cards
    //       and then laying them out using auto layout. If this
    //       becomes a performance issue, e.g., when there are a lot
    //       child cards, it could be changed to have a placeholder
    //       with the right width for each card, but only build and
    //       layout the child card when it's becoming visible soon.
    // See: https://gitlab.com/SkedGo/tripgo-cards-ios/issues/3
    
    let contents = pageCard.cards.map { card -> UIView in
      guard let view = card.buildCardView() else {
        preconditionFailure("Can only include cards in a page view that have a card!")
      }
      view.applyStyling(pageCard.style)

      card.cardView = view
      card.didBuild(cardView: view, headerView: nil)
      
      view.dismissButton?.addTarget(pageCard, action: #selector(TGPageCard.dismissTapped(sender:)), for: .touchUpInside)
      
      return view
    }
    
    fill(with: contents)
    
    // Page card doesn't always start with page 0. So we keep a reference
    // to the first page index, which can then be used at a later point.
    visiblePageLogical = pageCard.initialPageIndex
    visiblePageLefty = isRightToLeft
      ? contents.count - 1 - pageCard.initialPageIndex
      : pageCard.initialPageIndex

    // This will be used in both `moveForward` and `moveBackward`, so
    // it's important to "initailise" this value correctly.
    lastHorizontalOffset = CGFloat(visiblePageLefty) * (frame.width + Constants.spaceBetweenCards)
    
    let topMost = cardView(index: visiblePageLogical)
    self.accessibilityElements = [topMost].compactMap { $0 }
    self.topView = topMost
  }
  
  override func updateDismissButton(show: Bool, isSpringLoaded: Bool) {
    super.updateDismissButton(show: show, isSpringLoaded: isSpringLoaded)

    cardViews.forEach { $0.updateDismissButton(show: show, isSpringLoaded: isSpringLoaded) }
  }
  
  private func fill(with contentViews: [UIView]) {
    // This is required to make connection from the leading edge
    // of the nth content view to the trailing edge of the (n-1)
    // content view.
    var previous: UIView!
    
    for (index, view) in contentViews.enumerated() {
      view.translatesAutoresizingMaskIntoConstraints = false
      self.contentView.addSubview(view)
      
      if index == 0 {
        // First content needs to be connected to the scroll
        // view's content view.
        view.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor).isActive = true
      } else {
        // Subsequent, non-last, content is connected to its
        // preceding sibling, but accounting for the space.
        view.leadingAnchor.constraint(equalTo: previous.trailingAnchor,
                                      constant: Constants.spaceBetweenCards).isActive = true
      }
      
      // All contents are connected to the top and bottom edges
      // of the scroll view's content.
      view.topAnchor.constraint(equalTo: self.contentView.topAnchor).isActive = true
      view.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor).isActive = true
      
      // All contents have the same width, which equals to the width of
      // the scroll view. Note that, scroll view is used here, instead
      // of its content view.
      view.widthAnchor.constraint(equalTo: self.pager.widthAnchor,
                                  constant: Constants.spaceBetweenCards * -1).isActive = true
      
      // The last content is connected to the trailing edge of the
      // scroll view's content view.
      if index == contentViews.count - 1 {
        view.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor,
                                       constant: Constants.spaceBetweenCards * -1).isActive = true
      }
      
      previous = view
    }
  }
  
  // MARK: - Content view configuration
  
  override func allowContentScrolling(_ allowScrolling: Bool) {
    cardViews.forEach { $0.contentScrollView?.isScrollEnabled = allowScrolling }
  }
  
  override func adjustContentAlpha(to value: CGFloat) {
    // not calling super on purpose.
    cardViews.forEach { $0.adjustContentAlpha(to: value) }
  }
  
  // MARK: - Navigation
  
  private var isRightToLeft: Bool {
    traitCollection.layoutDirection == .rightToLeft
  }
  
  private func currentLeftyIndex() -> Int {
    // Using `floor` here as we're getting fractions here, e.g., on iPhone X in landscape
    return Int(floor(pager.contentOffset.x) / (floor(frame.width) + Constants.spaceBetweenCards))
  }
  
  private func currentLogicalIndex() -> Int {
    let lefty = currentLeftyIndex()
    return isRightToLeft ? pageCount - lefty - 1 : lefty
  }
  
  var currentPage: Int {
    currentLogicalIndex()
  }
  
  func moveForward(animated: Bool = true) {
    if isRightToLeft {
      moveLeft(animated: animated)
    } else {
      moveRight(animated: animated)
    }
  }
  
  func moveBackward(animated: Bool = true) {
    if isRightToLeft {
      moveRight(animated: animated)
    } else {
      moveLeft(animated: animated)
    }
  }
  
  private func moveRight(animated: Bool) {
    // Assign `visiblePage` here so that we allow paging there even if VoiceOver is enabled
    visiblePageLefty = min(cardViews.count - 1, visiblePageLefty + 1)
    visiblePageLogical = isRightToLeft ? pageCount - visiblePageLefty - 1 : visiblePageLefty
    
    let topMost = cardView(index: visiblePageLogical)
    self.accessibilityElements = [topMost].compactMap { $0 }
    self.topView = topMost

    // Shift by the entire width of the card view
    let nextFullWidthHorizontalOffset = pager.contentOffset.x + frame.width + Constants.spaceBetweenCards
    
    // It's possible that the scroll view is in the middle of scrolling
    // when this method is called. In this case, the content offset may
    // not be at the start of the next full page. We use the variable
    // below to calculate where the start of the next full page should be.
    let nextFullPageHorizontalOffset = lastHorizontalOffset + frame.width + Constants.spaceBetweenCards
    
    // Maximum ensures we are always at the start of a page. It also
    // helps when the page view doesn't start with page 0 -> In this
    // case, we won't be moving to page 1, but to the page n + 1.
    let horizontalOffset = fmax(nextFullWidthHorizontalOffset, nextFullPageHorizontalOffset)
    
    // Make sure we don't go over.
    guard horizontalOffset < pager.contentSize.width else { return }
    
    pager.setContentOffset(CGPoint(x: horizontalOffset, y: 0), animated: animated)
    
    // Update the tracking property.
    lastHorizontalOffset = horizontalOffset
  }
  
  private func moveLeft(animated: Bool) {
    // Assign `visiblePage` here so that we allow paging there even if VoiceOver is enabled
    visiblePageLefty = max(0, visiblePageLefty - 1)
    visiblePageLogical = isRightToLeft ? pageCount - visiblePageLefty - 1 : visiblePageLefty

    let topMost = cardView(index: visiblePageLogical)
    self.accessibilityElements = [topMost].compactMap { $0 }
    self.topView = topMost

    // See `moveRight()` for comments.
    let nextFullWidthHorizontalOffset = pager.contentOffset.x - frame.width - Constants.spaceBetweenCards
    let nextFullPageHorizontalOffset = lastHorizontalOffset - frame.width - Constants.spaceBetweenCards
    let horizontalOffset = fmax(nextFullPageHorizontalOffset, nextFullWidthHorizontalOffset)
    
    // We don't wanna go off screen.
    guard horizontalOffset >= 0 else { return }
    
    pager.setContentOffset(CGPoint(x: horizontalOffset, y: 0), animated: animated)
    
    lastHorizontalOffset = horizontalOffset
  }
  
  func move(to cardIndex: Int, animated: Bool = true) {
    let leftIndex = isRightToLeft
      ? pageCount - cardIndex - 1
      : cardIndex
    
    // index must fall within the range of available content cards.
    guard 0..<contentView.subviews.count ~= leftIndex else { return }

    // Assign `visiblePage` here so that we allow paging there even if VoiceOver is enabled
    visiblePageLefty = leftIndex
    visiblePageLogical = cardIndex

    let topMost = cardView(index: visiblePageLogical)
    self.accessibilityElements = [topMost].compactMap { $0 }
    self.topView = topMost

    let newX = (frame.width + Constants.spaceBetweenCards) * CGFloat(leftIndex)
    pager.setContentOffset(CGPoint(x: newX, y: 0), animated: animated)
  }
  
}

// MARK: -

extension TGPageCardView: UIScrollViewDelegate {
  
  // This delegate is called in response to setContentOffset(_, animated).
  // We use it here to detect the end of scrolling due to user pressing a
  // button, i.e., scrolling programmatically.
  func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
    scrollViewDidComeToCompleteStop(scrollView)
  }
  
  // This delegate is called in response to actual user scrolling. We use
  // it here to detect the end of scrolling due to users actually swiping
  // between pages.
  func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    scrollViewDidComeToCompleteStop(scrollView)
  }
  
  private func scrollViewDidComeToCompleteStop(_ scrollView: UIScrollView) {
    // Don't allow paging by scrolling when VoiceOver is running. This is working
    // around a weird behaviour in (at least) iOS 15 that immediately scrolls to
    // offset.y == 0 on presenting the initial page.
    let logical = currentLogicalIndex()
    if UIAccessibility.isVoiceOverRunning, visiblePageLogical != logical {
      move(to: visiblePageLogical, animated: false)
      return
    }
    
    visiblePageLogical = logical
    delegate?.didChangeCurrentPage(to: logical, animated: true)
    lastHorizontalOffset = scrollView.contentOffset.y
    
    let topMost = cardView(index: logical)
    self.accessibilityElements = [topMost].compactMap { $0 }
    self.topView = topMost
  }
  
}
