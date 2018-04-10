//
//  ExampleCustomTitleCard.swift
//  TGCardViewController
//
//  Created by Kuan Lun Huang on 10/4/18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import UIKit
import TGCardViewController

class ExampleCustomTitleCard: TGPlainCard {
  
  init() {
    let content = ExampleChildContentView.instantiate()
    let titleView = TurnByTurnTitleView.newInstance()
    super.init(title: .custom(titleView), contentView: content, mapManager: .sydney)
    
    titleView.dismissButton.addTarget(self, action: #selector(dismissButtonTapped(_:)), for: .touchUpInside)
  }

  @objc private func dismissButtonTapped(_ sender: Any) {
    controller?.pop()
  }
}
