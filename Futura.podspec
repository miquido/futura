Pod::Spec.new do |s|

  s.name         = "Futura"
  s.version      = "1.0.0"
  s.summary      = "Simple yet powerful promise library in Swift"
  s.description  = "Futura is a small library that provides simple yet powerful implementation of promises for iOS and macOS."
  s.homepage     = "https://www.miquido.com/"
  s.license      = { :type => "Apache 2.0", :file => "LICENSE" }
  s.author       = { "Kacper Kaliński" => "kacper.kalinski@miquido.com" }
  s.source       = { :git => "https://github.com/miquido/futura.git", :tag => "#{s.version}" }
  s.source_files = "Futura/Futura/*.swift"

end