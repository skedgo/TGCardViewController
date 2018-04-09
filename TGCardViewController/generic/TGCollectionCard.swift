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
open class TGCollectionCard: TGCard {
  
  let accessoryView: UIView?
  
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
  
  public init(title: String, subtitle: String? = nil,
              dataSource: UICollectionViewDataSource? = nil,
              delegate: UICollectionViewDelegate? = nil,
              layout: UICollectionViewLayout,
              accessoryView: UIView? = nil,
              mapManager: TGCompatibleMapManager? = nil,
              initialPosition: TGCardPosition? = nil) {
    
    self.collectionViewDataSource = dataSource
    self.collectionViewDelegate = delegate
    self.accessoryView = accessoryView
    self.collectionViewLayout = layout
    
    super.init(title: title, subtitle: subtitle,
               mapManager: mapManager, initialPosition: mapManager != nil ? initialPosition : .extended)
  }
  
  // MARK: - Constructing views
  
  open override func buildCardView(showClose: Bool, includeHeader: Bool) -> TGCardView {
    let view = TGScrollCardView.instantiate()
    view.configure(with: self, showClose: showClose, includeHeader: includeHeader)
    return view
  }
  
}
