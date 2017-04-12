//
//  TGPageCardView.swift
//  TGCardViewController
//
//  Created by Kuan Lun Huang on 18/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit


protocol TGPageCardViewDelegate: class {
  
  func didChangeCurrentPage(to index: Int)
  
}

class TGPageCardView: TGCardView {
  
  fileprivate enum Constants {
    static let animationDuration: Double = 0.4
    static let spaceBetweenCards: CGFloat = 5
  }
  
  @IBOutlet weak var pager: UIScrollView!
  
  @IBOutlet weak var contentView: UIView!

  @IBOutlet weak var pagerTrailingConstant: NSLayoutConstraint!
  
  fileprivate var lastHorizontalOffset: CGFloat = 0

  weak var delegate: TGPageCardViewDelegate?
  
  var cardViews: [TGCardView] {
    return (contentView.subviews as? [TGCardView]) ?? []
  }
  
  override var headerHeight: CGFloat {
    guard contentView.subviews.count > 0 else { return 0 }
    
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
  
  override var pagingScrollView: UIScrollView? {
    get {
      return pager
    }
    set {}
  }
  
  override var contentScrollView: UIScrollView? {
    get {
      guard currentPage < cardViews.count else {
        return nil
      }
      
      return cardViews[currentPage].contentScrollView
    }
    set {}
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    
    // remove corner as we want each card to show its own corners
    layer.mask = nil
  }
  
  // MARK: - New instance
  
  static func instantiate() -> TGPageCardView {
    let bundle = Bundle(for: self)
    guard
      let view = bundle.loadNibNamed("TGPageCardView", owner: nil, options: nil)!.first as? TGPageCardView
      else { preconditionFailure() }
    return view
    
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    pagerTrailingConstant.constant = Constants.spaceBetweenCards
  }
  
  // MARK: - Navigation
  
  var currentPage: Int {
    return Int(pager.contentOffset.x / (frame.width + Constants.spaceBetweenCards))
  }
  
  func moveForward(animated: Bool = true) {
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
  
  func moveBackward(animated: Bool = true) {
    let newX = pager.contentOffset.x - frame.width - Constants.spaceBetweenCards
    
    // We don't wanna go off screen.
    guard newX >= 0 else { return }
    
    pager.setContentOffset(CGPoint(x: newX, y: 0), animated: animated)
  }
  
  func move(to cardIndex: Int, animated: Bool = true) {
    // index must fall within the range of available content cards.
    guard 0..<contentView.subviews.count ~= cardIndex else { return }
    
    let newX = (frame.width + Constants.spaceBetweenCards) * CGFloat(cardIndex)
    
    pager.setContentOffset(CGPoint(x: newX, y: 0), animated: animated)
  }
  
  // MARK: - Configuration
  
  func configure(with card: TGPageCard) {

    // TODO: This does a lot of work by building all the child cards
    //       and then laying them out using auto layout. If this
    //       becomes a performance issue, e.g., when there are a lot
    //       child cards, it could be changed to have a placeholder
    //       with the right width for each card, but only build and
    //       layout the child card when it's becoming visible soon.
    // See: https://gitlab.com/SkedGo/tripgo-cards-ios/issues/3
    
    let contents = card.cards.map { card -> UIView in
      let view = card.buildCardView(showClose: false, includeHeader: false)
      card.didBuild(cardView: view, headerView: nil)
      return view
    }
    
    fill(with: contents)
  }
  
  override func allowContentScrolling(_ allowScrolling: Bool) {
    cardViews.forEach { $0.contentScrollView?.isScrollEnabled = allowScrolling }
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
  
}

extension TGPageCardView: UIScrollViewDelegate {
  
  // This delegate is called in response to setContentOffset(_, animated).
  // We use it here to detect the end of scrolling due to user pressing a
  // button, i.e., scrolling programmatically.
  func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
    delegate?.didChangeCurrentPage(to: currentPage)
  }
  
  // This delegate is called in response to actual user scrolling. We use
  // it here to detect the end of scrolling due to users actually swiping
  // between pages.
  func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    delegate?.didChangeCurrentPage(to: currentPage)
  }
  
}
