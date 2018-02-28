//
//  ExampleTableDataSource.swift
//  TGCardViewController
//
//  Created by Adrian Schoenig on 16/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import MapKit

import TGCardViewController

class ExampleTableDataSource: NSObject {
  
  var onSelect: ((MKAnnotation) -> Void)?
  
  fileprivate var stops = [
    [
      "lat": 51.4642,
      "lng": -0.1703,
      "name": "Clapham Junction",
      ],
    [
      "lat": 51.5037,
      "lng": -0.111,
      "name": "London Waterloo East",
      ],
    [
      "lat": 51.3755,
      "lng": -0.0928,
      "name": "East Croydon",
      ],
    [
      "lat": 51.5051,
      "lng": -0.0861,
      "name": "London Bridge",
      ],
    [
      "lat": 51.4652,
      "lng": -0.0136,
      "name": "Lewisham",
      ],
    [
      "lat": 51.4953,
      "lng": -0.1446,
      "name": "London Victoria",
      ],
    [
      "lat": 51.5114,
      "lng": -0.0567,
      "name": "Shadwell",
      ],
    [
      "lat": 51.4862,
      "lng": -0.1229,
      "name": "Vauxhall",
      ],
    [
      "lat": 51.4932,
      "lng": -0.0475,
      "name": "Surrey Quays",
      ],
    [
      "lat": 51.498,
      "lng": -0.0497,
      "name": "Canada Water",
      ],
    [
      "lat": 51.5044,
      "lng": -0.0559,
      "name": "Wapping",
      ],
    [
      "lat": 51.5008,
      "lng": -0.052,
      "name": "Rotherhithe",
      ],
    [
      "lat": 51.4212,
      "lng": -0.2064,
      "name": "Wimbledon",
      ],
    [
      "lat": 51.5419,
      "lng": -0.0034,
      "name": "Stratford (London)",
      ],
    [
      "lat": 51.4751,
      "lng": -0.0404,
      "name": "New Cross Gate ELL",
      ],
    [
      "lat": 51.397,
      "lng": -0.0752,
      "name": "Norwood Junction",
      ],
    [
      "lat": 51.518,
      "lng": -0.0814,
      "name": "London Liverpool Street",
      ],
    [
      "lat": 51.5387,
      "lng": -0.0757,
      "name": "Haggerston",
      ],
    [
      "lat": 51.5234,
      "lng": -0.0752,
      "name": "Shoreditch High Street",
      ],
    [
      "lat": 51.5315,
      "lng": -0.0757,
      "name": "Hoxton",
      ],
    [
      "lat": 51.548,
      "lng": -0.1915,
      "name": "West Hampstead Thameslink",
      ],
    [
      "lat": 51.4393,
      "lng": -0.0532,
      "name": "Forest Hill",
      ],
    [
      "lat": 51.4647,
      "lng": -0.0375,
      "name": "Brockley",
      ],
    [
      "lat": 51.4273,
      "lng": -0.0542,
      "name": "Sydenham",
      ],
    [
      "lat": 51.45,
      "lng": -0.0455,
      "name": "Honor Oak Park",
      ],
    [
      "lat": 51.47,
      "lng": -0.0694,
      "name": "Peckham Rye",
      ],
    [
      "lat": 51.4432,
      "lng": -0.1524,
      "name": "Balham",
      ],
    [
      "lat": 51.516,
      "lng": -0.1762,
      "name": "London Paddington",
      ],
    [
      "lat": 51.4,
      "lng": 0.0173,
      "name": "Bromley South",
      ],
    [
      "lat": 51.4423,
      "lng": -0.1877,
      "name": "Earlsfield",
      ],
    [
      "lat": 51.4474,
      "lng": 0.2193,
      "name": "Dartford",
      ],
    [
      "lat": 51.3733,
      "lng": 0.0891,
      "name": "Orpington",
      ],
    [
      "lat": 51.5461,
      "lng": -0.1038,
      "name": "Highbury & Islington",
      ],
    [
      "lat": 51.4658,
      "lng": 0.0089,
      "name": "Blackheath",
      ],
    [
      "lat": 51.5123,
      "lng": -0.0402,
      "name": "Limehouse",
      ],
    [
      "lat": 51.5195,
      "lng": -0.0598,
      "name": "Whitechapel",
      ],
    [
      "lat": 51.5487,
      "lng": -0.0922,
      "name": "Canonbury",
      ],
    [
      "lat": 51.5323,
      "lng": -0.1269,
      "name": "London St Pancras International",
      ],
    [
      "lat": 51.5119,
      "lng": -0.5915,
      "name": "Slough",
      ],
    ].map { dict -> MKAnnotation in
      let point = MKPointAnnotation()
      point.coordinate = CLLocationCoordinate2DMake(dict["lat"] as! Double, dict["lng"] as! Double)
      point.title = dict["name"] as? String
      return point
  }
  
}

extension ExampleTableDataSource : UITableViewDelegate {
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    onSelect?(stops[indexPath.row])
  }
  
  func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return true
  }
  
  func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
    return [
      UITableViewRowAction(style: .destructive, title: "Delete") { _, ip in
        self.stops.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .automatic)
      }
    ]
  }
  
  func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
    let item = stops.remove(at: sourceIndexPath.row)
    stops.insert(item, at: destinationIndexPath.row)
  }
  
}

extension ExampleTableDataSource : UITableViewDataSource {
  
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return stops.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let tableCell = UITableViewCell(style: .default, reuseIdentifier: nil)
    let row = indexPath.row
    tableCell.textLabel?.text = "#\(row): \(stops[row].title!!)"
    return tableCell
  }
  
}

@available(iOS 11.0, *)
extension ExampleTableDataSource : UITableViewDragDelegate {

  func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
    let string = (stops[indexPath.row].title ?? nil) ?? "Hello"
    let item = UIDragItem(itemProvider: NSItemProvider(item: string as NSString, typeIdentifier: "public.text"))
    return [ item ]
  }
  
}

@available(iOS 11.0, *)
extension ExampleTableDataSource : UITableViewDropDelegate {
  
  func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
  }
  
  func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
    // To allow iPhone specific re-ordering
    if session.localDragSession != nil {
      return UITableViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    } else {
      return UITableViewDropProposal(operation: .copy, intent: .automatic)
    }
  }
  
}
