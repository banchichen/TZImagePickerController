Pod::Spec.new do |s|
  s.name         = "TZImagePickerController"
  s.version      = "1.1.1"
  s.summary      = "A clone of UIImagePickerController, support picking multiple photos、original photo and video"
  s.homepage     = "https://github.com/banchichen/TZImagePickerController"
  s.license      = "MIT"
  s.author       = { "banchichen" => "736420282@qq.com" }
  s.platform     = :ios
  s.ios.deployment_target = "6.0"
  s.source       = { :git => "https://github.com/banchichen/TZImagePickerController.git", :tag => "1.1.1" }
  s.requires_arc = true
  s.resources    = "TZImagePickerController/TZImagePickerController/Resource/*.{png,xib,nib}"
  s.source_files = "TZImagePickerController/TZImagePickerController/*.{h,m}"
end