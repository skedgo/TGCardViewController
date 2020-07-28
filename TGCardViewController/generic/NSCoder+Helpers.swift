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
  
  func decodeArchived<T: NSCoding>(_ type: T.Type, forKey key: String) -> T? where T: NSObject {
    guard let data = decodeObject(forKey: key) as? Data else { return nil }
    do {
      return try NSKeyedUnarchiver.unarchivedObject(ofClass: type, from: data)
    } catch {
      assertionFailure("Decoding failed due to: \(error)")
      return nil
    }
  }
  
  func decodeArchived<T: NSCoding>(_ type: [T].Type, forKey key: String) -> [T]? {
    guard let data = decodeObject(forKey: key) as? Data else { return nil }
    do {
      return try NSKeyedUnarchiver.unarchivedObject(ofClasses: [T.self, NSArray.self], from: data) as? [T]
    } catch {
      assertionFailure("Decoding failed due to: \(error)")
      return nil
    }

  }
  
  func encodeArchive<T: NSCoding>(_ object: T?, forKey key: String) {
    guard let object = object else { return }
    do {
      try encode(NSKeyedArchiver.archivedData(withRootObject: object, requiringSecureCoding: false), forKey: key)
    } catch {
      assertionFailure("Encoding failed due to: \(error)")
    }
  }
  
  func encodeArchive<T: NSCoding>(_ objects: [T]?, forKey key: String) {
    guard let objects = objects else { return }
    do {
      try encode(NSKeyedArchiver.archivedData(withRootObject: objects, requiringSecureCoding: false), forKey: key)
    } catch {
      assertionFailure("Encoding failed due to: \(error)")
    }
  }
  
}
