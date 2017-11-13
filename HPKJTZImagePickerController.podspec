Pod::Spec.new do |s|
  s.name         = "HPKJTZImagePickerController"
  s.version      = "2.0.3"
  s.summary      = "A clone of UIImagePickerController, support picking multiple photos、original photo and video"
  s.homepage     = "https://github.com/banchichen/TZImagePickerController"
  s.license      = "MIT"
  s.author       = { "banchichen" => "tanzhenios@foxmail.com" }
  s.platform     = :ios
  s.ios.deployment_target = "6.0"
  s.source       = { :git => "https://github.com/huapukeji/TZImagePickerController.git", :tag => "2.0.3" }
  s.requires_arc = true
  s.resources    = "TZImagePickerController/TZImagePickerController/*.{png,xib,nib,bundle}"
  s.source_files = "TZImagePickerController/TZImagePickerController/*.{h,m}"
end
