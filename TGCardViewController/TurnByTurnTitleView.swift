//
//  TurnByTurnTitleView.swift
//  Example
//
//  Created by Kuan Lun Huang on 10/4/18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import TGCardViewController

class TurnByTurnTitleView: UIView, TGDismissableTitleView {
  
  @IBOutlet weak var dismissButton: UIButton!
  
  var dismissHandler: TGDismissableTitleView.DismissHandler?
  
  override func awakeFromNib() {
    super.awakeFromNib()
    dismissButton.addTarget(self, action: #selector(dismissButtonTapped(_:)), for: .touchUpInside)
  }
  static func newInstance() -> TurnByTurnTitleView {
    let bundle = Bundle(for: self)
    return bundle.loadNibNamed("TurnByTurnTitleView", owner: self, options: nil)?.first as! TurnByTurnTitleView
  }
  
  @objc private func dismissButtonTapped(_ sender: Any) {
    dismissHandler?(sender)
  }

}


