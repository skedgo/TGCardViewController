Pod::Spec.new do |s|
  s.name         = "TGCardViewController"
  s.version      = "1.7.0"
  s.summary      = "Card-based view controller for mapping apps"

  s.description  = <<-DESC
    A view controller with a map and a stack of cards. Cards can work both
    as a hierarchy like a navigation controller and as a list like a page
    controller - or a combination thereof.
                   DESC

  s.homepage     = "https://github.com/skedgo/TGCardViewController"
  # s.screenshots  = "www.example.com/screenshots_1.gif", "www.example.com/screenshots_2.gif"

  s.license      = 'Apache License, Version 2.0'
  s.authors             = { "Adrian Schoenig": "adrian@skedgo.com",
                            "Brian Huang": "brian@skedgo.com" }

  # ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  s.platform     = :ios, "12.4"
  s.swift_version = '5.4'

  # ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  s.source       = { :git => "https://github.com/skedgo/TGCardViewController.git", :tag => "#{s.version}" }


  # ――― Source Code + Resources ―――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  s.source_files  = "Sources/TGCardViewController/**/*.swift"
  s.resources = "Sources/TGCardViewController/**/*.xib"

end
