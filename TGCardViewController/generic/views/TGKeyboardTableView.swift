//
//  TGKeyboardTableView.swift
//  TGCardViewController
//
//  Created by Adrian Schönig on 08.05.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

/// A table view that allows navigation and selection using a hardware keyboard.
/// Only supports a single section.
///
/// Kudos to [@douglashill]( https://gist.github.com/douglashill/50728432881ef37e8b49f2a5917f462d).
class TGKeyboardTableView: UITableView {

  // These properties may be set or overridden to provide discoverability titles for key commands.
  var selectAboveDiscoverabilityTitle: String?
  var selectBelowDiscoverabilityTitle: String?
  var selectTopDiscoverabilityTitle: String?
  var selectBottomDiscoverabilityTitle: String?
  var clearSelectionDiscoverabilityTitle: String?
  var activateSelectionDiscoverabilityTitle: String?
  
  private(set) var selectedViaKeyboard: Bool = false
  
  enum Selection {
    case top
    case bottom
    case nextItem
    case previousItem
//    case nextSection
//    case previousSection
  }
  
  override var canBecomeFirstResponder: Bool {
    return true
  }
  
  override var keyCommands: [UIKeyCommand]? {
    var commands = super.keyCommands ?? []
    
    // Arrow navigation
    commands.append(UIKeyCommand(
      input: UIKeyCommand.inputUpArrow, modifierFlags: [], action: #selector(selectAbove),
      maybeDiscoverabilityTitle: selectAboveDiscoverabilityTitle
    ))
    commands.append(UIKeyCommand(
      input: UIKeyCommand.inputDownArrow, modifierFlags: [], action: #selector(selectBelow),
      maybeDiscoverabilityTitle: selectBelowDiscoverabilityTitle
    ))
    commands.append(UIKeyCommand(
      input: UIKeyCommand.inputUpArrow, modifierFlags: .command, action: #selector(selectTop),
      maybeDiscoverabilityTitle: selectTopDiscoverabilityTitle
    ))
    commands.append(UIKeyCommand(
      input: UIKeyCommand.inputDownArrow, modifierFlags: .command, action: #selector(selectBottom),
      maybeDiscoverabilityTitle: selectBottomDiscoverabilityTitle
    ))
    
    // Deselect
    commands.append(UIKeyCommand(
      input: UIKeyCommand.inputEscape, modifierFlags: [], action: #selector(clearSelection),
      maybeDiscoverabilityTitle: clearSelectionDiscoverabilityTitle
    ))
    
    // Select
    commands.append(UIKeyCommand(
      input: " ", modifierFlags: [], action: #selector(activateSelection)))
    commands.append(UIKeyCommand(
      input: "\r", modifierFlags: [], action: #selector(activateSelection),
      maybeDiscoverabilityTitle: activateSelectionDiscoverabilityTitle
    ))
    
    return commands
  }
  
  @objc func selectAbove() {
    if let oldSelectedIndexPath = indexPathForSelectedRow {
      selectRow(.previousItem)
    } else {
      selectBottom()
    }
  }
  
  @objc func selectBelow() {
    if let oldSelectedIndexPath = indexPathForSelectedRow {
      selectRow(.nextItem)
    } else {
      selectTop()
    }
  }
  
  @objc func selectTop() {
    selectRow(.top)
  }
  
  @objc func selectBottom() {
    selectRow(.bottom)
  }
  
  /// Tries to select and scroll to the row at the given index in section 0.
  /// Does not require the index to be in bounds. Does nothing if out of bounds.
  private func selectRow(_ selection: Selection) {
    guard numberOfSections > 0, numberOfRows(inSection: 0) > 0 else { return }

    var indexPath: IndexPath
    switch selection {
    case .top:
      indexPath = IndexPath(item: 0, section: 0)
    case .bottom:
      indexPath = IndexPath(item: -1, section: 0)
    case .nextItem:
      guard let selection = indexPathForSelectedRow else { return }
      indexPath = IndexPath(item: selection.row + 1, section: selection.section)
    case .previousItem:
      guard let selection = indexPathForSelectedRow else { return }
      indexPath = IndexPath(item: selection.row - 1, section: selection.section)
    }
    
    if indexPath.item < 0 {
      indexPath.section -= 1
      if indexPath.section < 0 {
        indexPath.section = numberOfSections - 1
      }
      indexPath.item = numberOfRows(inSection: indexPath.section) - 1
    }
    if indexPath.item >= numberOfRows(inSection: indexPath.section) {
      indexPath.section += 1
      if indexPath.section >= numberOfSections {
        indexPath.section = 0
      }
      indexPath.item = 0
    }
    
    selectedViaKeyboard = true
    
    switch cellVisibility(atIndexPath: indexPath) {
    case .fullyVisible:
      selectRow(at: indexPath, animated: false, scrollPosition: .none)
    case .notFullyVisible(let scrollPosition):
      // Looks better and feel more responsive if the selection updates without animation.
      selectRow(at: indexPath, animated: false, scrollPosition: .none)
      scrollToRow(at: indexPath, at: scrollPosition, animated: true)
      flashScrollIndicators()
    }
  }
  
  /// Whether a row is fully visible, or if not if it’s above or below the viewport.
  enum CellVisibility { case fullyVisible; case notFullyVisible(ScrollPosition); }
  
  /// Whether the given row is fully visible, or if not if it’s above or below the viewport.
  private func cellVisibility(atIndexPath indexPath: IndexPath) -> CellVisibility {
    let rowRect = rectForRow(at: indexPath)
    if #available(iOS 11.0, *) {
      if bounds.inset(by: adjustedContentInset).contains(rowRect) {
        return .fullyVisible
      }
    } else {
      if bounds.inset(by: contentInset).contains(rowRect) {
        return .fullyVisible
      }
    }
    
    let position: ScrollPosition = rowRect.midY < bounds.midY ? .top : .bottom
    return .notFullyVisible(position)
  }
  
  @objc func clearSelection() {
    selectedViaKeyboard = false
    selectRow(at: nil, animated: false, scrollPosition: .none)
  }
  
  @objc func activateSelection() {
    guard let indexPathForSelectedRow = indexPathForSelectedRow else {
      return
    }
    #if targetEnvironment(macCatalyst)
    // Arguably this is the wrong way around, but Catalyst
    // itself implements up/down arrow interaction and
    // overrides ours and it selects in this case already
    // calling the `didSelectRowAt:` delegate... so to
    // differentiate we only have highlighting left.
    delegate?.tableView?(self, didHighlightRowAt: indexPathForSelectedRow)
    #else
    delegate?.tableView?(self, didSelectRowAt: indexPathForSelectedRow)
    #endif
  }
}

private extension UIKeyCommand {
  convenience init(input: String, modifierFlags: UIKeyModifierFlags, action: Selector,
                   maybeDiscoverabilityTitle: String?) {
    if #available(iOS 13.0, *) {
      self.init(
        title: "", image: nil,
        action: action,
        input: input, modifierFlags: modifierFlags,
        discoverabilityTitle: maybeDiscoverabilityTitle
      )
    } else {
      if let discoverabilityTitle = maybeDiscoverabilityTitle {
        self.init(input: input, modifierFlags: modifierFlags, action: action, discoverabilityTitle: discoverabilityTitle)
      } else {
        self.init(input: input, modifierFlags: modifierFlags, action: action)
      }
    }
  }
}
