//
//  ExampleRootCard.swift
//  TGCardViewController
//
//  Created by Adrian Schoenig on 9/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit
import MapKit

import TGCardViewController

class ExampleRootCard : TGTableCard {
  
  fileprivate let source = DataSource()
  
  init() {
    super.init(title: "Card Demo", dataSource: source, delegate: source, mapManager: .nuremberg)
    
    source.onSelect = { item in
      self.controller?.push(item.card)
    }
    
    // Custom styling
    self.backgroundColor = #colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1)
    self.titleTextColor = .white
    self.subtitleTextColor = .white
    self.subtitleFont = UIFont.italicSystemFont(ofSize: 15)
    self.grabHandleColor = .white
    
    // Floating views
    let infoButton = UIButton(type: .infoLight)
    infoButton.backgroundColor = #colorLiteral(red: 1, green: 0.7137254902, blue: 0.7568627451, alpha: 1)
    infoButton.tintColor = .white
    NSLayoutConstraint.activate([
        infoButton.widthAnchor.constraint(equalToConstant: 45),
        infoButton.heightAnchor.constraint(equalToConstant: 45)
      ])
    infoButton.addTarget(self, action: #selector(infoButtonPressed), for: .touchUpInside)
    self.topMapToolBarItems = [infoButton]
    
    let contactAddButton = UIButton(type: .contactAdd)
    contactAddButton.backgroundColor = #colorLiteral(red: 1, green: 0.7137254902, blue: 0.7568627451, alpha: 1)
    contactAddButton.tintColor = .white
    NSLayoutConstraint.activate([
        contactAddButton.widthAnchor.constraint(equalToConstant: 45),
        contactAddButton.heightAnchor.constraint(equalToConstant: 45)
      ])
    contactAddButton.addTarget(self, action: #selector(addContactButtonPressed), for: .touchUpInside)
    self.bottomMapToolBarItems = [contactAddButton]
  }
  
  override func didBuild(cardView: TGCardView, headerView: TGHeaderView?) {
    super.didBuild(cardView: cardView, headerView: headerView)
    
    guard let tableView = (cardView as? TGTableCardView)?.tableView else { return }
    
    if #available(iOS 11.0, *) {
      tableView.isSpringLoaded = true
    }
  }
  
  // MARK: - User interaction
  
  @objc
  private func infoButtonPressed() {
    let alertCtr = UIAlertController(title: "Alert", message: "I'm an info button", preferredStyle: .alert)
    alertCtr.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
    controller?.present(alertCtr, animated: true, completion: nil)
  }
  
  @objc
  private func addContactButtonPressed() {
    let alertCtr = UIAlertController(title: "Alert", message: "I'm an contact add button", preferredStyle: .alert)
    alertCtr.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
    controller?.present(alertCtr, animated: true, completion: nil)
  }
  
}

// MARK: -

extension UIButton {
  
  static func dummySystemButton() -> UIButton {
    let dummy = UIButton(type: .detailDisclosure)
    dummy.widthAnchor.constraint(equalToConstant: 45).isActive = true
    dummy.heightAnchor.constraint(equalToConstant: 45).isActive = true
    dummy.backgroundColor = #colorLiteral(red: 1, green: 0.7137254902, blue: 0.7568627451, alpha: 1)
    dummy.tintColor = .white
    return dummy
  }
}

// MARK: -

fileprivate class DataSource : NSObject, UITableViewDelegate, UITableViewDataSource {
  
  typealias Item = (title: String, card: TGCard)
  
  var onSelect: ((Item) -> Void)?
  
  let items: [Item] = [
    (title: "Show Mock-up", card: MockupRootCard()),
    (title: "Show Erlking", card: ExampleChildCard()),
    (title: "Show Table",   card: ExampleTableCard(mapManager: .london)),
    (title: "Show Pages",   card: ExamplePageCard()),
    (title: "Custom title", card: ExampleCustomTitleCard())
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
    tableCell.textLabel?.text = items[row].title
    return tableCell
  }
  
}
