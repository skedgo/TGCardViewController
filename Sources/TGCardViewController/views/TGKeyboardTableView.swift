//
//  TGKeyboardTableView.swift
//  TGCardViewController
//
//  Created by Adrian Schönig on 08.05.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

/// A table view that allows navigation and selection using a hardware keyboard.
///
/// Adopted from [@douglashill]( https://gist.github.com/douglashill/50728432881ef37e8b49f2a5917f462d).
class TGKeyboardTableView: UITableView {

  private(set) var selectedViaKeyboard: Bool = false
  
  // Used on Catalyst to intercept taps
  private let cellSelector = UITapGestureRecognizer()
  private let cellTapper = UITapGestureRecognizer()
  
  var handleMacSelection: (IndexPath) -> Void = { _ in }
  
  var clickToHighlightDoubleClickToSelect: Bool = false {
    didSet {
      cellSelector.isEnabled = clickToHighlightDoubleClickToSelect
      cellTapper.numberOfTapsRequired = clickToHighlightDoubleClickToSelect ? 2 : 1
    }
  }
  
  enum Selection {
    case top
    case bottom
    case nextItem
    case previousItem
//    case nextSection
//    case previousSection
  }
  
  override init(frame: CGRect, style: UITableView.Style) {
    super.init(frame: frame, style: style)
    didInit()
  }
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
    didInit()
  }
  
  private func didInit() {
    #if targetEnvironment(macCatalyst)
    cellSelector.addTarget(self, action: #selector(handleTapQuickly(_:)))
    addGestureRecognizer(cellSelector)

    cellTapper.addTarget(self, action: #selector(handleTap(_:)))
    addGestureRecognizer(cellTapper)
    #endif
  }
  
  override var canBecomeFirstResponder: Bool {
    return true
  }
  
  override var keyCommands: [UIKeyCommand]? {
    var commands = super.keyCommands ?? []
    
    // Arrow navigation
    commands.append(UIKeyCommand(
      input: UIKeyCommand.inputUpArrow, modifierFlags: [], action: #selector(selectAbove)
    ))
    commands.append(UIKeyCommand(
      input: UIKeyCommand.inputDownArrow, modifierFlags: [], action: #selector(selectBelow)
    ))
    commands.append(UIKeyCommand(
      input: UIKeyCommand.inputUpArrow, modifierFlags: .command, action: #selector(selectTop)
    ))
    commands.append(UIKeyCommand(
      input: UIKeyCommand.inputDownArrow, modifierFlags: .command, action: #selector(selectBottom)
    ))
    
    // Deselect
    commands.append(UIKeyCommand(
      input: UIKeyCommand.inputEscape, modifierFlags: [], action: #selector(clearSelection)
    ))
    
    // Select
    commands.append(UIKeyCommand(
      input: " ", modifierFlags: [], action: #selector(activateSelection)))
    commands.append(UIKeyCommand(
      input: "\r", modifierFlags: [], action: #selector(activateSelection)
    ))
    
    return commands
  }

  @objc func handleTapQuickly(_ recogniser: UITapGestureRecognizer) {
    guard let indexPath = indexPathForRow(at: recogniser.location(in: self)) else { return }
    
    switch recogniser.state {
    case .began, .recognized:
      cellForRow(at: indexPath)?.setHighlighted(true, animated: false)
      selectRow(at: indexPath, animated: false, scrollPosition: .none)

    default:
      break
    }
    
  }

  @objc func handleTap(_ recogniser: UITapGestureRecognizer) {
    guard let indexPath = indexPathForRow(at: recogniser.location(in: self)) else { return }

    // this allows triggering the actual action
    handleMacSelection(indexPath)

    // this makes sure it's selected, without jumping back
    // to the selection from the keyboard
    selectRow(at: indexPath, animated: false, scrollPosition: .none)
  }
  
  @objc func selectAbove() {
    if indexPathForSelectedRow != nil {
      selectRow(.previousItem)
    } else {
      selectBottom()
    }
  }
  
  @objc func selectBelow() {
    if indexPathForSelectedRow != nil {
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
    guard let indexPath = indexPathToSelect(for: selection) else { return }
    
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
  
  
  // swiftlint:disable cyclomatic_complexity
  private func indexPathToSelect(for selection: Selection) -> IndexPath? {
    guard numberOfSections > 0, numberOfRows(inSection: 0) > 0 else { return nil }

    var indexPath: IndexPath
    switch selection {
    case .top:
      indexPath = IndexPath(item: 0, section: 0)
    case .bottom:
      indexPath = IndexPath(item: -1, section: 0)
    case .nextItem:
      guard let selection = indexPathForSelectedRow else { return nil }
      indexPath = IndexPath(item: selection.row + 1, section: selection.section)
    case .previousItem:
      guard let selection = indexPathForSelectedRow else { return nil }
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
    return indexPath
  }
  // swiftlint:enable cyclomatic_complexity
  
  /// Whether a row is fully visible, or if not if it’s above or below the viewport.
  enum CellVisibility { case fullyVisible; case notFullyVisible(ScrollPosition); }
  
  /// Whether the given row is fully visible, or if not if it’s above or below the viewport.
  private func cellVisibility(atIndexPath indexPath: IndexPath) -> CellVisibility {
    let rowRect = rectForRow(at: indexPath)
    if bounds.inset(by: adjustedContentInset).contains(rowRect) {
      return .fullyVisible
    }
    
    let position: ScrollPosition = rowRect.midY < bounds.midY ? .top : .bottom
    return .notFullyVisible(position)
  }
  
  @objc func clearSelection() {
    selectedViaKeyboard = false
    selectRow(at: nil, animated: false, scrollPosition: .none)
  }
  
  @objc func activateSelection() {
    guard let indexPathForSelectedRow = indexPathForSelectedRow else { return }
    
    #if targetEnvironment(macCatalyst)
    // We don't call the delegate, as Catalyst itself implements up/down arrow
    // interaction, overriding ours and it selects in this case already
    // while navigating through the list by calling the `didSelectRowAt:`
    // delegate... so we instead call our own method, and leave it to the
    // caller to implement
    handleMacSelection(indexPathForSelectedRow)
    #else
    delegate?.tableView?(self, didSelectRowAt: indexPathForSelectedRow)
    #endif
  }
}
