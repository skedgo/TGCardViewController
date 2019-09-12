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
class TGKeyboardTableView: UITableView {

  // These properties may be set or overridden to provide discoverability titles for key commands.
  var selectAboveDiscoverabilityTitle: String?
  var selectBelowDiscoverabilityTitle: String?
  var selectTopDiscoverabilityTitle: String?
  var selectBottomDiscoverabilityTitle: String?
  var clearSelectionDiscoverabilityTitle: String?
  var activateSelectionDiscoverabilityTitle: String?
  
  private(set) var selectedViaKeyboard: Bool = false
  
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
      selectRowAtIndex(oldSelectedIndexPath.row - 1)
    } else {
      selectBottom()
    }
  }
  
  @objc func selectBelow() {
    if let oldSelectedIndexPath = indexPathForSelectedRow {
      selectRowAtIndex(oldSelectedIndexPath.row + 1)
    } else {
      selectTop()
    }
  }
  
  @objc func selectTop() {
    selectRowAtIndex(0)
  }
  
  @objc func selectBottom() {
    selectRowAtIndex(numberOfRows(inSection: 0) - 1)
  }
  
  /// Tries to select and scroll to the row at the given index in section 0.
  /// Does not require the index to be in bounds. Does nothing if out of bounds.
  private func selectRowAtIndex(_ rowIndex: Int) {
    guard rowIndex >= 0 && rowIndex < numberOfRows(inSection: 0) else {
      return
    }
    
    selectedViaKeyboard = true

    let indexPath = IndexPath(row: rowIndex, section: 0)
    
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
    delegate?.tableView?(self, didSelectRowAt: indexPathForSelectedRow)
  }
}

private extension UIKeyCommand {
  convenience init(input: String, modifierFlags: UIKeyModifierFlags, action: Selector,
                   maybeDiscoverabilityTitle: String?) {
    if let discoverabilityTitle = maybeDiscoverabilityTitle {
      self.init(input: input, modifierFlags: modifierFlags, action: action, discoverabilityTitle: discoverabilityTitle)
    } else {
      self.init(input: input, modifierFlags: modifierFlags, action: action)
    }
  }
}
