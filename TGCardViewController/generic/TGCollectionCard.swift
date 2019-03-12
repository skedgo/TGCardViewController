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
  
  public required init?(coder: NSCoder) {
    guard let layout = coder.decodeArchived(UICollectionViewLayout.self, forKey: "collectionViewLayout") else {
      return nil
    }
    self.collectionViewLayout = layout
    super.init(coder: coder)
  }
  
  open override func encode(with aCoder: NSCoder) {
    super.encode(with: aCoder)
    aCoder.encodeArchive(collectionViewLayout, forKey: "collectionViewLayout")
  }
  
  // MARK: - Constructing views
  
  open override func buildCardView() -> TGCardView {
    let view = TGScrollCardView.instantiate()
    view.configure(with: self)
    return view
  }

}
