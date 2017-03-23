//
//  TGScrollCardView.swift
//  TGCardViewController
//
//  Created by Kuan Lun Huang on 18/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit
import RxSwift

class TGScrollCardView: TGCardView {
  
  @IBOutlet weak var pager: UIScrollView!
  
  @IBOutlet weak var contentView: UIView!
  
  fileprivate let disposeBag = DisposeBag()
  
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
  
//  override var contentScrollViews: [UIScrollView] {
//    get {
//      guard let cardViews = contentView.subviews as? [TGCardView] else {
//        return []
//      }
//      
//      return cardViews.flatMap { $0.scrollView }
//    }
//    set {}
//  }
  
  // MARK: - New instance
  
  static func instantiate() -> TGScrollCardView {
    let bundle = Bundle(for: self)
    return bundle.loadNibNamed("TGScrollCardView", owner: nil, options: nil)!.first as! TGScrollCardView
  }
  
  // MARK: - Navigation
  
  func moveForward(animated: Bool = true) {
    // Shift by the entire width of the card view
    let newX = pager.contentOffset.x + frame.width
    
    // Make sure we don't go over.
    guard newX < pager.contentSize.width else { return }
    
    if animated {
      UIView.animate(withDuration: 0.4, animations: { 
        self.pager.contentOffset = CGPoint(x: newX, y: 0)
      })
    } else {
      pager.contentOffset = CGPoint(x: newX, y: 0)
    }
  }
  
  func moveBackward(animated: Bool = true) {
    let newX = pager.contentOffset.x - frame.width
    
    // We don't wanna go off screen.
    guard newX >= 0 else { return }
    
    if animated {
      UIView.animate(withDuration: 0.4, animations: { 
        self.pager.contentOffset = CGPoint(x: newX, y: 0)
      })
    } else {
      pager.contentOffset = CGPoint(x: newX, y: 0)
    }
  }
  
  func move(to cardIndex: Int, animated: Bool = true) {
    // index must fall within the range of available content cards.
    guard 0..<contentView.subviews.count ~= cardIndex else { return }
    
    let newX = frame.width * CGFloat(cardIndex)
    
    if animated {
      UIView.animate(withDuration: 0.4) {
        self.pager.contentOffset = CGPoint(x: newX, y: 0)
      }
    } else {
      pager.contentOffset = CGPoint(x: newX, y: 0)
    }
  }
  
  // MARK: - Configuration
  
  func configure(with card: TGScrollCard) {
    let contents = card.contentCards.map { $0.buildView(showClose: false) }
    fill(with: contents)
    
    card.rx_currentPageIndex
      .distinctUntilChanged()
      .subscribe(onNext: { [weak self] in
        self?.move(to: $0)
      })
      .addDisposableTo(disposeBag)
  }
  
  override func allowContentScrolling(_ allowScrolling: Bool) {
    guard let cardViews = contentView.subviews as? [TGCardView] else { return }
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
        // preceding sibling.
        view.leadingAnchor.constraint(equalTo: previous.trailingAnchor).isActive = true
      }
      
      // All contents are connected to the top and bottom edges
      // of the scroll view's content.
      view.topAnchor.constraint(equalTo: self.contentView.topAnchor).isActive = true
      view.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor).isActive = true
      
      // All contents have the same width, which equals to the width of
      // the scroll view. Note that, scroll view is used here, instead
      // of its content view.
      view.widthAnchor.constraint(equalTo: self.pager.widthAnchor).isActive = true
      
      // The last content is connected to the trailing edge of the
      // scroll view's content view.
      if index == contentViews.count - 1 {
        view.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor).isActive = true
      }
      
      previous = view
    }
  }
  
}
