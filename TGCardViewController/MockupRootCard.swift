//
//  MockupRootCard.swift
//  TGCardViewController
//
//  Created by Adrian Schoenig on 16/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit
import MapKit

class MockupRootCard : TGTableCard {
  
  fileprivate let source = DataSource()
  
  init() {
    super.init(title: "TripGo Mock-up", dataSource: source, delegate: source)
    
    source.onSelect = { item in
      self.controller?.push(item.card)
    }
  }

}

fileprivate class DataSource : NSObject, UITableViewDelegate, UITableViewDataSource {

  typealias Item = (title: String, card: TGCard)
  
  var onSelect: ((Item) -> Void)?
  
  enum Mockup {
    case agenda
    case routes
    case event
    
    var card: TGCard {
      let home = MKPointAnnotation()
      home.coordinate = CLLocationCoordinate2DMake(-33.913144, 151.237732)
      
      let laureate = MKPointAnnotation()
      laureate.coordinate = CLLocationCoordinate2DMake(-33.877026, 151.206072)
      
      switch self {
      case .agenda:
        return MockupImageCard(title: "Agenda", image: #imageLiteral(resourceName: "agenda"), locations: [home, laureate], targets: [
          (0.14 ..< 0.17, Mockup.routes.card),
          (0.17 ..< 0.25, Mockup.event.card),
          (0.33 ..< 0.36, Mockup.routes.card),
          (0.44 ..< 0.47, Mockup.routes.card),
          (0.47 ..< 0.55, Mockup.event.card),
          (0.55 ..< 0.58, Mockup.routes.card),
          ])

      case .event:
        return MockupImageCard(title: "Work Laureate", image: #imageLiteral(resourceName: "agenda-event"), locations: [laureate])

      case .routes:
        return MockupImageCard(title: "Routes", image: #imageLiteral(resourceName: "routes"))
      }
    }
  }
  
  let items: [Item] = [
    (title: "Agenda", card: Mockup.agenda.card),
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
