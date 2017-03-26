//
//  ExampleRootCard.swift
//  TGCardViewController
//
//  Created by Adrian Schoenig on 9/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit
import MapKit

class ExampleRootCard : TGTableCard {
  
  fileprivate let source = DataSource()
  
  init() {
    super.init(title: "Card Demo", dataSource: source, delegate: source, mapManager: .nuremberg)
    
    source.onSelect = { item in
      self.controller?.push(item.card)
    }
  }
  
}

fileprivate class DataSource : NSObject, UITableViewDelegate, UITableViewDataSource {
  
  typealias Item = (title: String, card: TGCard)
  
  var onSelect: ((Item) -> Void)?
  
  let items: [Item] = [
    (title: "Show Mock-up", card: MockupRootCard()),
    (title: "Show Erlking", card: ExampleChildCard()),
    (title: "Show Table",   card: ExampleTableCard()),
    (title: "Show Agenda",  card: ExampleAgendaCard()),
    (title: "Show Pages",   card: ExampleScrollCard()),
  ]
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    onSelect?(items[indexPath.row])
  }
  
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return items.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let tableCell = UITableViewCell(style: .default, reuseIdentifier: nil)
    let row = indexPath.row
    tableCell.textLabel?.text = items[row].card.title
    return tableCell
  }
  
}
