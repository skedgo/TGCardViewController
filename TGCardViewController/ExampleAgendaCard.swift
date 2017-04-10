//
//  ExampleAgendaCard.swift
//  TGCardViewController
//
//  Created by Kuan Lun Huang on 15/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

class ExampleAgendaCard: TGAgendaCard {
  
  fileprivate let source = ExampleTableDataSource()
  
  init() {
    let container = UIView()
    let label = UILabel()
    label.text = "This is where weekly selector goes"
    label.center(on: container)
    super.init(title: "Agenda", dataSource: source, delegate: source, bottomContent: container)
    
    floatingButtonAction = { [unowned self] in
      let dummyController = UIViewController()
      dummyController.view.backgroundColor = .white
      let cancel = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(self.cancelButtonPressed(_:)))
      dummyController.navigationItem.leftBarButtonItem = cancel
      let modal = UINavigationController(rootViewController: dummyController)
      self.controller?.present(modal, animated: true, completion: nil)
    }
  }
  
  @objc
  private func cancelButtonPressed(_ sender: Any) {
    controller?.dismiss(animated: true, completion: nil)
  }
  
}
