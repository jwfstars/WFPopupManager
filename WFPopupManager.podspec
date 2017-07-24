# --use-libraries 

Pod::Spec.new do |s|
  s.name         = 'WFPopupManager'
  s.version      = '0.1.0'
  s.license = { :type => 'MIT', :text => <<-LICENSE
                   Copyright (c) 2016 江文帆. All rights reserved.
                 LICENSE
               }
  s.homepage     = 'https://github.com/jwfstars/WFPopupManager.git'
  s.authors      =  { "江文帆" => "jwfstars@icloud.com" }
  s.summary      = 'WFPopupManager'

  s.platform     =  :ios, '8.0'
  s.source       =  { :git => 'https://github.com/jwfstars/WFPopupManager.git', :tag => s.version }

  s.source_files = 'WFPopupManager/**/*.{h,m}'
  s.frameworks   =  'Foundation',  'UIKit'
  s.requires_arc = true
  
# Pod Dependencies
end
