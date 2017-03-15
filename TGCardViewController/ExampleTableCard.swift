//
//  ExampleTableCard.swift
//  TGCardViewController
//
//  Created by Adrian Schoenig on 10/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

class ExampleTableCard : TGTableCard {

  fileprivate let source = ExampleDataSource()

  init() {
    super.init(title: "Table", dataSource: source, delegate: source, bottomView: UIView())
  }
  
}

fileprivate class ExampleDataSource: NSObject {
}

extension ExampleDataSource : UITableViewDelegate {
}

extension ExampleDataSource : UITableViewDataSource {
  
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 30
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let tableCell = UITableViewCell(style: .default, reuseIdentifier: nil)
    tableCell.textLabel?.text = "Table cell #\(indexPath.row)"
    return tableCell

  }
  
}
