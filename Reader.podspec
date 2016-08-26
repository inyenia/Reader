Pod::Spec.new do |s|
 s.name = 'Reader'
 s.version = '2.8.10'
 s.license = 'MIT'
 s.summary = 'The open source PDF file reader/viewer for iOS.'
 s.homepage = 'http://www.vfr.org/'
 s.authors = { "Jesus Lopez" => "inyenia@gmail.com" }
 s.source = { :git => 'https://github.com/inyenia/Reader.git', :tag => "2.8.10" }
 s.platform = :ios
 s.ios.deployment_target = '6.0'
 s.source_files = 'Sources/**/*.{h,m}'
 s.resources = 'Graphics/Reader-*.png'
 s.frameworks = 'UIKit', 'Foundation', 'CoreGraphics', 'QuartzCore', 'ImageIO', 'MessageUI'
 s.requires_arc = true
end
