//
//  NSCoder+Helpers.swift
//  TGCardViewController
//
//  Created by Adrian Schönig on 03.08.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import MapKit

extension NSCoder {
  func decodeView(forKey key: String) -> UIView? {
    return decodeArchived(UIView.self, forKey: key)
  }
  
  func encode(view: UIView?, forKey key: String) {
    // For some reason, encoding the view directly doesn't work. We end up
    // with `nil` for that key. Archiving it to data first works.
    encodeArchive(view, forKey: key)
  }
  
  func decode(forKey key: String) -> MKMapRect? {
    guard let array = decodeObject(forKey: key) as? [Double], array.count == 4 else {
      return nil
    }
    return MKMapRect(origin: MKMapPoint(x: array[0], y: array[1]), size: MKMapSize(width: array[2], height: array[3]))
  }
  
  func encode(_ mapRect: MKMapRect?, forKey key: String) {
    guard let mapRect = mapRect, mapRect.origin.x > 0, mapRect.origin.y > 0, mapRect.size.height > 0 else {
      return
    }
    encode([mapRect.origin.x, mapRect.origin.y, mapRect.size.width, mapRect.size.height], forKey: key)
  }  

  
  // MARK: Generic
  
  func decodeArchived<T>(_ type: T.Type, forKey key: String) -> T? {
    guard let data = decodeObject(forKey: key) as? Data else { return nil }
    return NSKeyedUnarchiver.unarchiveObject(with: data) as? T
  }
  
  func decodeArchived<T>(_ type: [T].Type, forKey key: String) -> [T]? {
    guard let data = decodeObject(forKey: key) as? Data else { return nil }
    return NSKeyedUnarchiver.unarchiveObject(with: data) as? [T]
  }
  
  func encodeArchive<T>(_ object: T?, forKey key: String) {
    guard let object = object else { return }
    encode(NSKeyedArchiver.archivedData(withRootObject: object), forKey: key)
  }
  
  func encodeArchive<T>(_ objects: [T]?, forKey key: String) {
    guard let objects = objects else { return }
    encode(NSKeyedArchiver.archivedData(withRootObject: objects), forKey: key)
  }
  
}
