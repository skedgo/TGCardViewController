//
//  TGAgendaCardView.swift
//  TGCardViewController
//
//  Created by Kuan Lun Huang on 15/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

@available(*, deprecated, message: "Scheduled for deletion. Use a custom class instead.")
public class TGAgendaCardView: TGCardView {
  
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
    guard
      let view = bundle.loadNibNamed("TGAgendaCardView", owner: nil, options: nil)!.first as? TGAgendaCardView
      else { preconditionFailure() }
    return view
  }
  
  // MARK: - Configuration
  
  override func configure(with card: TGCard, includeTitleView: Bool, whenDismiss: ((Any) -> Void)?) {
    guard let agendaCard = card as? TGAgendaCard else {
      preconditionFailure()
    }
    
    super.configure(with: agendaCard, includeTitleView: includeTitleView, whenDismiss: whenDismiss)
    
    tableView.delegate = agendaCard.tableViewDelegate
    tableView.dataSource = agendaCard.tableViewDataSource
    
    if #available(iOS 11, *) {
      tableView.dragDelegate = agendaCard.tableViewDelegate as? UITableViewDragDelegate
      tableView.dropDelegate = agendaCard.tableViewDelegate as? UITableViewDropDelegate
    }
    
    if let bottomContent = agendaCard.bottomContentView {
      bottomViewContainer.addSubview(bottomContent)
      bottomContent.snap(to: bottomViewContainer)
      
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
