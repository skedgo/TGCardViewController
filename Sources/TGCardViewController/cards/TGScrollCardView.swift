//
//  TGScrollCardView.swift
//  TGCardViewController
//
//  Created by Adrian Schoenig on 9/4/18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

@available(*, unavailable, renamed: "TGScrollCardView")
public typealias TGTableCardView = TGScrollCardView

/// The view for the card used by `TGTableCard` and `TGCollectionCard`.
///
/// Cannot be subclassed, but is used to get access to the card view's
/// `UITableView` or `UICollectionView.
public class TGScrollCardView: TGCardView {
  
  weak var embeddedScrollView: UIScrollView!
  
  // This is where the scroll view is going to be. We didn't insert
  // scroll view directly because the particular instance and style
  // is only known at run time. Using a wrapper helps us fix the
  // constraints at design time.
  @IBOutlet public internal(set) weak var scrollViewWrapper: UIView!
  
  // MARK: - New instances
  
  static func instantiate() -> TGScrollCardView {
    guard
      let view = Bundle.module.loadNibNamed("TGScrollCardView", owner: nil, options: nil)!.first as? TGScrollCardView
      else { preconditionFailure() }
    return view
  }

  // MARK: - Configuration
  
  override func configure(with card: TGCard) {
    let scrollView: UIScrollView
    if let tableCard = card as? TGTableCard {
      let tableView = TGKeyboardTableView(frame: .zero, style: tableCard.tableStyle)
      tableView.backgroundColor = .clear
      tableView.dataSource = tableCard.tableViewDataSource
      tableView.delegate = tableCard.tableViewDelegate

      // For convenience, we also assign the delegate for dragging
      // and dropping directly if possible.
      tableView.dragDelegate = tableCard.tableViewDelegate as? UITableViewDragDelegate
      tableView.dropDelegate = tableCard.tableViewDelegate as? UITableViewDropDelegate

      scrollView = tableView

    } else if let collectionCard = card as? TGCollectionCard {
      let collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionCard.collectionViewLayout)
      collectionView.backgroundColor = .clear
      collectionView.dataSource = collectionCard.collectionViewDataSource
      collectionView.delegate = collectionCard.collectionViewDelegate

      // For convenience, we also assign the delegate for dragging
      // and dropping directly if possible.
      collectionView.dragDelegate = collectionCard.collectionViewDelegate as? UICollectionViewDragDelegate
      collectionView.dropDelegate = collectionCard.collectionViewDelegate as? UICollectionViewDropDelegate

      scrollView = collectionView

    } else {
      preconditionFailure()
    }
    
    self.configure(scrollView, with: card)
  }
  
  open func configure(_ scrollView: UIScrollView, with card: TGCard) {
    super.configure(with: card)
    
    scrollViewWrapper.addSubview(scrollView)
    scrollView.snap(to: scrollViewWrapper)
    
    self.embeddedScrollView = scrollView
    contentScrollView = scrollView
  }
  
  override func applyStyling(_ style: TGCardStyle) {
    super.applyStyling(style)
    
    #if targetEnvironment(macCatalyst)
    backgroundColor = .clear
    #else
    scrollViewWrapper.backgroundColor = style.backgroundColor
    #endif
  }
  
}

extension TGScrollCardView {
  public var tableView: UITableView? {
    return embeddedScrollView as? UITableView
  }

  public var collectionView: UICollectionView? {
    return embeddedScrollView as? UICollectionView
  }
}
