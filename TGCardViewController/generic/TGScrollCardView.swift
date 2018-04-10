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

public class TGScrollCardView: TGCardView {
  
  public weak var embeddedScrollView: UIScrollView!
  
  // This is where the scroll view is going to be. We didn't insert
  // scroll view directly because the particular instance and style
  // is only known at run time. Using a wrapper helps us fix the
  // constraints at design time.
  @IBOutlet weak var scrollViewWrapper: UIView!
  
  // MARK: - New instances
  
  static func instantiate() -> TGScrollCardView {
    let bundle = Bundle(for: self)
    guard
      let view = bundle.loadNibNamed("TGScrollCardView", owner: nil, options: nil)!.first as? TGScrollCardView
      else { preconditionFailure() }
    return view
  }

  // MARK: - Configuration
  
  override func configure(with card: TGCard, includeTitleView: Bool) {
    super.configure(with: card, includeTitleView: includeTitleView)
    
    let scrollView: UIScrollView
    
    if let tableCard = card as? TGTableCard {
      let tableView = UITableView(frame: .zero, style: tableCard.tableStyle)
      tableView.backgroundColor = .clear
      tableView.dataSource = tableCard.tableViewDataSource
      tableView.delegate = tableCard.tableViewDelegate
      if #available(iOS 11.0, *) {
        // For convenience, we also assign the delegate for dragging
        // and dropping directly if possible.
        tableView.dragDelegate = tableCard.tableViewDelegate as? UITableViewDragDelegate
        tableView.dropDelegate = tableCard.tableViewDelegate as? UITableViewDropDelegate
      }
      scrollView = tableView

    } else if let collectionCard = card as? TGCollectionCard {
      let collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionCard.collectionViewLayout)
      collectionView.backgroundColor = .clear
      collectionView.dataSource = collectionCard.collectionViewDataSource
      collectionView.delegate = collectionCard.collectionViewDelegate
      if #available(iOS 11.0, *) {
        // For convenience, we also assign the delegate for dragging
        // and dropping directly if possible.
        collectionView.dragDelegate = collectionCard.collectionViewDelegate as? UICollectionViewDragDelegate
        collectionView.dropDelegate = collectionCard.collectionViewDelegate as? UICollectionViewDropDelegate
      }
      scrollView = collectionView

    } else {
      preconditionFailure()
    }
    
    scrollViewWrapper.addSubview(scrollView)
    scrollView.snap(to: scrollViewWrapper)
    
    self.embeddedScrollView = scrollView
    contentScrollView = scrollView
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
