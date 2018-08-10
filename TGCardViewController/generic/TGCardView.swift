//
//  TGCardView.swift
//  TGCardViewController
//
//  Created by Adrian Schoenig on 9/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

/// The view for the card itself.
///
/// Cannot be subclassed, by usually used to programatically update the
/// title/subtitle of the card or to get access to the card's table view or
/// collection view - by checking if an instance of this class is a
/// `TGScrollCardView` instance.
public class TGCardView: TGCornerView {
  
  /// Each card view needs a grab handle, which the controller
  /// might hide and show.
  @IBOutlet weak var grabHandle: TGGrabHandleView?
  
  @IBOutlet weak var titleViewPlaceholder: UIView?
  
  /// This is the line separating the header and content parts of a
  /// card view.
  @IBOutlet weak var contentSeparator: UIView?
  
  /// Optional floating button.
  ///
  /// The button is only visible when the corresponding action closure
  /// is set.
  @IBOutlet weak var floatingButton: UIButton?
  
  /// Each card view needs a scroll view where the main content of the
  /// card goes. The card controller need access to it, in order to
  /// handling dragging the card up and down.
  @IBOutlet weak var contentScrollView: UIScrollView? {
    didSet {
      contentScrollViewObservation = contentScrollView?
        .observe(\UIScrollView.contentOffset) { [weak self] scrollView, _ in
        guard let separator = self?.contentSeparator, scrollView.isScrollEnabled else { return }
        separator.isHidden = scrollView.contentOffset.y <= 0
      }
    }
  }
  
  weak var titleView: UIView?
  
  private var contentScrollViewObservation: NSKeyValueObservation?
  
  /// Optional pager in which `contentScrollView` can be wrapped.
  ///
  /// - SeeAlso: `TGPageCardView` which relies on this.
  var pagingScrollView: UIScrollView?
  
  /// The height of the header part of the view, i.e., everything
  /// up to where `contentScrollView` starts.
  ///
  /// - Warning: Might not be accurate if the view hasn't been layed out.
  var headerHeight: CGFloat {
    guard let scrollView = contentScrollView else { return 0 }
    return scrollView.frame.minY
  }
  
  /// The closure to execute when the button is pressed.
  var onFloatingButtonPressed: (() -> Void)? {
    didSet {
      floatingButton?.isHidden = onFloatingButtonPressed == nil
    }
  }
  
  override public func awakeFromNib() {
    super.awakeFromNib()
    
    contentSeparator?.isHidden = true
    
    if let floatie = floatingButton {
      floatie.isHidden = true
      floatie.setImage(nil, for: .normal)
      floatie.setTitle(nil, for: .normal)      
    }
  }
  
  // MARK: - Content Configuration
  
  /// Updates the title and subtitle, when the `.default` title
  /// was used. Does nothing when something other than the
  /// `.default` title configuration was used.
  ///
  /// - Parameters:
  ///   - title: New title
  ///   - subtitle: New subtitle (optional)
  public func updateDefaultTitle(title: String, subtitle: String?) {
    guard let defaultView = titleView as? TGCardDefaultTitleView else {
      assertionFailure("Can only update titles for `.default` title case.")
      return
    }
    
    defaultView.configure(title: title, subtitle: subtitle)
  }
  
  func configure(with card: TGCard, includeTitleView: Bool) {
    if let placeholder = titleViewPlaceholder, includeTitleView {
      let titleView: UIView?
      switch card.title {
      case .default(let title, let subtitle, let accessoryView):
        let defaultTitleView = TGCardDefaultTitleView.newInstance()
        defaultTitleView.configure(title: title, subtitle: subtitle)
        defaultTitleView.accessoryView = accessoryView
        titleView = defaultTitleView
        
      case .custom(let view):
        titleView = view

      case .none:
        titleView = nil
      }
      
      if let titleView = titleView {
        placeholder.addSubview(titleView)
        titleView.snap(to: placeholder)
        self.titleView = titleView
      }
    }
    
    // Apply custom styling
    applyStyling(for: card)
    
    if let action = card.floatingButtonAction {
      // TODO: We should add an accessibility label here
      // See: https://gitlab.com/SkedGo/tripgo-cards-ios/merge_requests/14#note_27632714
      floatingButton?.setTitle(nil, for: .normal)
      
      switch action.style {
      case .add(let color):
        floatingButton?.setImage(TGCardStyleKit.imageOfFloatingButton(floatingButtonBackground: color), for: .normal)
      case .custom(let image):
        floatingButton?.setImage(image, for: .normal)
      }
      
      onFloatingButtonPressed = action.onPressed
    }
  }
  
  // MARK: - Title View Configuration
  
  var dismissButton: UIButton? {
    guard let defaultTitleView = titleViewPlaceholder?.subviews.first as? TGCardDefaultTitleView else {
      return nil
    }
    return defaultTitleView.dismissButton
  }
  
  func headerHeight(for position: TGCardPosition) -> CGFloat {
    guard let scrollView = contentScrollView else {
      return 0
    }
    
    switch position {
    case .collapsed:
      var frame: CGRect
      
      if let titlePlaceholder = titleViewPlaceholder,
        let defaultTitleView = titlePlaceholder.subviews.first as? TGCardDefaultTitleView,
        let accessoryPlaceholder = defaultTitleView.accessoryViewContainer,
        let accessory = accessoryPlaceholder.subviews.first {
        // The frame of the accessory view in the coordinate system
        // of card view itself
        frame = accessoryPlaceholder.convert(accessory.frame, to: self)
      } else {
        // The frame of the scroll view in the coordinate system of
        // card view itself. Note, the scroll view may be embedded
        // inside another view, so we check for its superview here.
        frame = scrollView.superview?.convert(scrollView.frame, to: self) ?? scrollView.frame
      }
      
      if let handle = grabHandle {
        // If we have a grab handle, need to account for whether its hidden. If
        // its hideen, its space in the card view is reduced to 0.
        return handle.isHidden ? frame.minY - handle.frame.height : frame.minY
      } else {
        return frame.minY
      }
      
    default:
      return scrollView.superview?.convert(scrollView.frame, to: self).minY ?? scrollView.frame.minY
    }
  }
  
  // MARK: - Managing Appearance
  
  func applyStyling(for card: TGCard) {
    grabHandle?.handleColor = card.grabHandleColor
    backgroundColor = card.backgroundColor
    
    if let defaultTitleView = titleViewPlaceholder?.subviews.first as? TGCardDefaultTitleView {
      defaultTitleView.titleLabel.font = card.titleFont
      defaultTitleView.titleLabel.textColor = card.titleTextColor
      defaultTitleView.subtitleLabel.font = card.subtitleFont
      defaultTitleView.subtitleLabel.textColor = card.subtitleTextColor
    }
  }
  
  // MARK: - Content view configuration
  
  func allowContentScrolling(_ allowScrolling: Bool) {
    contentScrollView?.isScrollEnabled = allowScrolling
  }
  
  func adjustContentAlpha(to value: CGFloat) {
    contentScrollView?.alpha = value
  }
  
  // MARK: - User interaction
  
  @IBAction func floatingButtonTapped(_ sender: Any) {
    onFloatingButtonPressed?()
  }
}
