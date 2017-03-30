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


extension MKPointAnnotation {
  
  // @nonobjc due to this: http://stackoverflow.com/a/32831677/196990
  @nonobjc static var home = MKPointAnnotation(lat: -33.913144, lng: 151.237732)
  @nonobjc static var laureate = MKPointAnnotation(lat: -33.877026, lng: 151.206072)
  @nonobjc static var busStop = MKPointAnnotation(lat: -33.9132, lng: 151.2395)

}

fileprivate enum Mockup {
  
  
  fileprivate enum Trip {
    case walkBus
    
    var card: TGCard {
      switch self {
      case .walkBus:
        return MockupImageCard(
          title: "To Laureate", subtitle: "From Home", image: #imageLiteral(resourceName: "overview"),
          locations: [MKPointAnnotation.home, MKPointAnnotation.busStop, MKPointAnnotation.laureate],
          targets: [
            (0.11 ..< 0.22, pager(start: 0)),
            (0.22 ..< 0.33, pager(start: 1)),
            (0.33 ..< 0.44, pager(start: 3)),
            (0.44 ..< 0.55, pager(start: 4)),
          ]
        )
      }
    }
    
    var modeByMode: [ModeByMode] {
      switch self {
      case .walkBus: return [.walk, .busDepartures, .busStops, .walk, .eta]
      }
    }
    
    func pager(start: Int) -> TGPageCard {
      return TGPageCard(title: "Trip", cards: modeByMode.map { $0.card }, initialPage: start)
    }
  }
  
  
  fileprivate enum ModeByMode {
    
    case walk
    case busDepartures
    case busStops
    case eta
    case arrived
    
    var card: TGCard {
      switch self {
        
      case .walk:
        return MockupImageCard(title: "Walk 200m", subtitle: "To Belmore Road", image: #imageLiteral(resourceName: "mxm-walk"), locations: [MKPointAnnotation.home, MKPointAnnotation.busStop])
        
      case .busDepartures:
        return MockupImageCard(title: "Take bus", subtitle: "From Belmore Rd near Alison Rd", image: #imageLiteral(resourceName: "mxm-bus-departures"), locations: [MKPointAnnotation.busStop, MKPointAnnotation.laureate])
        
      case .busStops:
        return MockupImageCard(title: "Take bus", subtitle: "To City", image: #imageLiteral(resourceName: "mxm-bus-stops"), locations: [MKPointAnnotation.busStop, MKPointAnnotation.laureate])
        
      case .eta:
        return MockupImageCard(title: "To Laureate", subtitle: "From Home", image: #imageLiteral(resourceName: "mxm-eta"), locations: [MKPointAnnotation.laureate])
        
      case .arrived:
        return MockupImageCard(title: "To Laureate", subtitle: "From Home", image: #imageLiteral(resourceName: "mxm-arrived"), locations: [MKPointAnnotation.laureate])
      }
    }
    
  }
  
  
  case agenda
  case routes
  case event
  case trips([Trip])
  case modeByMode([ModeByMode])
  
  var card: TGCard {
    
    switch self {
    case .agenda:
      return MockupImageCard(title: "Agenda", image: #imageLiteral(resourceName: "agenda"), locations: [MKPointAnnotation.home, MKPointAnnotation.laureate], targets: [
        (0.14 ..< 0.17, Mockup.routes.card),
        (0.17 ..< 0.25, Mockup.event.card),
        (0.33 ..< 0.36, Mockup.routes.card),
        (0.44 ..< 0.47, Mockup.routes.card),
        (0.47 ..< 0.55, Mockup.event.card),
        (0.55 ..< 0.58, Mockup.routes.card),
        ])
      
    case .event:
      return MockupImageCard(title: "Work Laureate", image: #imageLiteral(resourceName: "agenda-event"), locations: [MKPointAnnotation.laureate], targets: [
          (0.025 ..< 0.14, Mockup.trips([.walkBus]).card)
        ])
      
    case .routes:
      return MockupImageCard(title: "Routes", image: #imageLiteral(resourceName: "routes"), targets: [
          (0    ..< 0.12, Mockup.trips([.walkBus, .walkBus]).card),
          (0.12 ..< 0.24, Mockup.trips([.walkBus, .walkBus]).card),
        ])
      
    case .trips(let trips):
      if trips.count == 1, let trip = trips.first {
        return trip.card
      } else {
        return TGPageCard(title: "Trips", cards: trips.map { $0.card })
      }
      
    case .modeByMode(let steps):
      return TGPageCard(title: "Trip", cards: steps.map { $0.card })
    }
  }
}


fileprivate class DataSource : NSObject, UITableViewDelegate, UITableViewDataSource {

  typealias Item = (title: String, card: TGCard)
  
  var onSelect: ((Item) -> Void)?
  
  let items: [Item] = [
    (title: "Agenda", card: Mockup.agenda.card),
    (title: "Mode by mode", card: Mockup.Trip.walkBus.pager(start: 0)),
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
