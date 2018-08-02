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
/// - warning: `TGCollectionCard` does *not* support state restoration out of the
///     box. To support this, override `init(coder:)` in your subclass as a
///     convenience initialiser and implement it yourself. You can also
///     override `encode(with:)` - no need to call super for that.
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
  
  public required init?(coder: NSCoder) {
    return nil
  }
  
  // MARK: - Constructing views
  
  open override func buildCardView(includeTitleView: Bool) -> TGCardView {
    let view = TGScrollCardView.instantiate()
    view.configure(with: self, includeTitleView: includeTitleView)
    return view
  }

}
