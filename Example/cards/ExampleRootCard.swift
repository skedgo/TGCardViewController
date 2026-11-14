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
  
  fileprivate let source: DataSource
  
  /// - Parameter offersTabs: Whether to offer showing the cards in a tab
  init(offersTabs: Bool = true) {
    source = DataSource(offersTabs: offersTabs)

    let title: CardTitle
    #if targetEnvironment(macCatalyst)
    title = .none
    #else
    title = .default("Card Demo")
    #endif
    super.init(title: title, dataSource: source, delegate: source, mapManager: TGMapManager.nuremberg, initialPosition: .collapsed)
    
    source.onSelect = { item in
      switch item.destination {
      case .card(let card):
        self.controller?.push(card)
      case .tabs:
        self.controller?.present(ExampleTabBarController(), animated: true)
      }
    }
    handleMacSelection = source.handleSelection

    // Custom styling
    style.subtitleFont = UIFont.italicSystemFont(ofSize: 15)
    #if targetEnvironment(macCatalyst)
    style.backgroundColor = .clear
    style.titleTextColor = .label
    style.subtitleTextColor = .label
    style.grabHandleColor = .label
    style.backgroundColor = UIColor(named: "cardBackground") ?? #colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1)
    style.titleTextColor = .white
    style.subtitleTextColor = .white
    style.grabHandleColor = .white
    #endif
    
    // Floating views
    let infoButton = UIButton(type: .infoLight)
//    infoButton.backgroundColor = #colorLiteral(red: 1, green: 0.7137254902, blue: 0.7568627451, alpha: 1)
//    infoButton.tintColor = .white
    NSLayoutConstraint.activate([
        infoButton.widthAnchor.constraint(equalToConstant: 45),
        infoButton.heightAnchor.constraint(equalToConstant: 45)
      ])
    infoButton.addTarget(self, action: #selector(infoButtonPressed), for: .touchUpInside)
    self.topMapToolBarItems = [infoButton]
    
    let contactAddButton = UIButton(type: .contactAdd)
//    contactAddButton.backgroundColor = #colorLiteral(red: 1, green: 0.7137254902, blue: 0.7568627451, alpha: 1)
//    contactAddButton.tintColor = .white
    NSLayoutConstraint.activate([
        contactAddButton.widthAnchor.constraint(equalToConstant: 45),
        contactAddButton.heightAnchor.constraint(equalToConstant: 45)
      ])
    contactAddButton.addTarget(self, action: #selector(addContactButtonPressed), for: .touchUpInside)
    self.bottomMapToolBarItems = [contactAddButton]
  }
  
  override func didBuild(tableView: UITableView) {
    super.didBuild(tableView: tableView)
    
    tableView.backgroundColor = .clear
    tableView.isSpringLoaded = true
  }
  
  // MARK: - User interaction
  
  @objc
  private func infoButtonPressed() {
    let alertCtr = UIAlertController(title: "Alert", message: "I'm an info button", preferredStyle: .alert)
    alertCtr.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
    controller?.present(alertCtr, animated: true)
  }
  
  @objc
  private func addContactButtonPressed() {
    let alertCtr = UIAlertController(title: "Alert", message: "I'm an contact add button", preferredStyle: .alert)
    alertCtr.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
    controller?.present(alertCtr, animated: true)
  }
  
}

// MARK: -

extension UIButton {
  
  static func dummyDetailDisclosureButton() -> UIButton {
    let dummy = UIButton(type: .detailDisclosure)
    dummy.widthAnchor.constraint(equalToConstant: 45).isActive = true
    dummy.heightAnchor.constraint(equalToConstant: 45).isActive = true
    dummy.backgroundColor = #colorLiteral(red: 1, green: 0.7137254902, blue: 0.7568627451, alpha: 1)
    dummy.tintColor = .white
    return dummy
  }
  
  static func dummyInfoLightButton() -> UIButton {
    let dummy = UIButton(type: .infoLight)
    dummy.widthAnchor.constraint(equalToConstant: 45).isActive = true
    dummy.heightAnchor.constraint(equalToConstant: 45).isActive = true
    dummy.backgroundColor = #colorLiteral(red: 0.8078431487, green: 0.02745098062, blue: 0.3333333433, alpha: 1)
    dummy.tintColor = .white
    return dummy
  }
  
}

// MARK: -

fileprivate class DataSource : NSObject, UITableViewDelegate, UITableViewDataSource {
  
  enum Destination {
    case card(TGCard)
    case tabs
  }
  
  typealias Item = (title: String, destination: Destination)
  
  var onSelect: ((Item) -> Void)?
  
  let items: [Item]
  
  init(offersTabs: Bool) {
    var items: [Item] = [
      (title: "Show Table",   destination: .card(ExampleTableCard())),
      (title: "Show Pages",   destination: .card(ExamplePageCard())),
      (title: "Custom title", destination: .card(ExampleCustomTitleCard())),
    ]
    if #available(iOS 16.0, *) {
      items.append((title: "Show Erlking", destination: .card(ExampleChildCard())))
    }
    if offersTabs {
      items.append((title: "Show in tab", destination: .tabs))
    }
    self.items = items
  }
  
  func handleSelection(_ indexPath: IndexPath) {
    onSelect?(items[indexPath.row])
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    #if !targetEnvironment(macCatalyst)
    handleSelection(indexPath)
    #endif
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
    tableCell.backgroundColor = .clear
    return tableCell
  }
  
}
