//
//  TGAgendaCardView.swift
//  TGCardViewController
//
//  Created by Kuan Lun Huang on 15/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

class TGAgendaCardView: TGCardView {
  
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var subtitleLabel: UILabel!
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var bottomViewContainer: UIView!
  
  /// Use this constraint to dynamically adjust the height of the bottom view
  ///
  /// The bottom view has a default height of 60pt. However, we can also find
  /// the fitting height for the content that goes into the bottom view and 
  /// use that value as the constant on the constraint as well.
  @IBOutlet weak var bottomViewContainerHeightConstraint: NSLayoutConstraint!
  
  /// Use this constraint to animate the bottom view up and down.
  ///
  /// This is a constraint connecting the top of the container to the bottom
  /// of the super view. To slide up, set a -ve constant value. Set to zero
  /// to slide down.
  @IBOutlet weak var bottomViewContainerTopConstraint: NSLayoutConstraint!
  
  // MARK: - New instances
  
  static func instantiate() -> TGAgendaCardView {
    let bundle = Bundle(for: self)
    return bundle.loadNibNamed("TGAgendaCardView", owner: nil, options: nil)!.first as! TGAgendaCardView
  }
  
  // MARK: - Configuration
  
  func configure(with card: TGAgendaCard, showClose: Bool, includeHeader: Bool) {
    titleLabel.text = includeHeader ? card.title : nil
    subtitleLabel.text = includeHeader ? card.subtitle : nil
    closeButton?.isHidden = !showClose
    tableView.delegate = card.tableViewDelegate
    tableView.dataSource = card.tableViewDataSource
    
    if let bottomContent = card.bottomContentView {
      bottomContent.snapOnAllEdges(to: bottomViewContainer)
      
      // Work out the fitting height for the content.
      let fittingHeight = bottomContent.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height
      
      // then, we adjust the height of the bottom view container to a value that
      // is big enough to accommodate the content.
      bottomViewContainerHeightConstraint.constant = fittingHeight
      
      // Don't forget to also adjust the top constraint as we want the bottom view
      // to slide up just enough to reveal its content.
      bottomViewContainerTopConstraint .constant = -1*fittingHeight
    }
  }
  
}

extension UIView {
  
  func snapOnAllEdges(to superView: UIView) {
    translatesAutoresizingMaskIntoConstraints = false
    superView.addSubview(self)
    topAnchor.constraint(equalTo: superView.topAnchor).isActive = true
    leadingAnchor.constraint(equalTo: superView.leadingAnchor).isActive = true
    trailingAnchor.constraint(equalTo: superView.trailingAnchor).isActive = true
    bottomAnchor.constraint(equalTo: superView.bottomAnchor).isActive = true
  }
  
  func center(on superView: UIView) {
    translatesAutoresizingMaskIntoConstraints = false
    superView.addSubview(self)
    topAnchor.constraint(equalTo: superView.topAnchor, constant: 8).isActive = true
    centerXAnchor.constraint(equalTo: superView.centerXAnchor).isActive = true
    centerYAnchor.constraint(equalTo: superView.centerYAnchor).isActive = true
  }
}
