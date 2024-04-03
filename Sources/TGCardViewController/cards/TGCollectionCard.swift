//
//  TGCollectionCard.swift
//  TGCardViewController
//
//  Created by Adrian Schönig on 09.04.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

/// A collection card is used for when you need a `UICollectionView`
/// as the card's content.
///
/// This class is generally subclassed.
///
/// - warning: `TGCollectionCard` supports state restoration, but will not
///     restore data sources and delegates. Override `init(coder:)` and
///     `encode(with:)` in your, making sure to call `super`.
open class TGCollectionCard: TGCard {
  
  public let collectionViewLayout: UICollectionViewLayout
  
  /// The delegate to be used for the card view's collection view.
  ///
  /// Only has an effect, if it is set before `buildCardView` is called, i.e.,
  /// before the card is pushed.
  public weak var collectionViewDelegate: UICollectionViewDelegate?
  
  /// The data source to be used for the card view's collection view.
  ///
  /// Only has an effect, if it is set before `buildCardView` is called, i.e.,
  /// before the card is pushed.
  public weak var collectionViewDataSource: UICollectionViewDataSource?
  
  // MARK: - Initialisers
  
  public init(title: CardTitle,
              dataSource: UICollectionViewDataSource? = nil,
              delegate: UICollectionViewDelegate? = nil,
              layout: UICollectionViewLayout,
              mapManager: TGCompatibleMapManager? = nil,
              initialPosition: TGCardPosition? = nil) {
    
    self.collectionViewDataSource = dataSource
    self.collectionViewDelegate = delegate
    self.collectionViewLayout = layout
    
    super.init(title: title, mapManager: mapManager, initialPosition: mapManager != nil ? initialPosition : .extended)
  }
  
  // MARK: - Card Life Cycle
  
  open func didBuild(collectionView: UICollectionView, headerView: TGHeaderView?) {
  }
  
  override public final func didBuild(cardView: TGCardView?, headerView: TGHeaderView?) {
    
    defer { super.didBuild(cardView: cardView, headerView: headerView) }
    
    guard
      let collectionView = (cardView as? TGScrollCardView)?.collectionView
      else { preconditionFailure() }
    
    didBuild(collectionView: collectionView, headerView: headerView)
  }

  // MARK: - Constructing views
  
  open override func buildCardView() -> TGCardView? {
    let view = TGScrollCardView.instantiate(extended: title.isExtended)
    view.configure(with: self)
    return view
  }

}
