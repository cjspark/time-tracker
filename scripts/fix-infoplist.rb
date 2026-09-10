#!/usr/bin/env ruby
# scripts/fix-infoplist.rb
# 把 INFOPLIST_FILE 指向 $(SRCROOT)/Info.plist（与 xcodeproj 同级）

begin
  require 'xcodeproj'
rescue LoadError
  puts "请先运行: gem install xcodeproj"
  exit 1
end

project_path = ARGV[0]
unless project_path
  puts "用法: ruby fix-infoplist.rb <path/to/Annuli.xcodeproj>"
  exit 1
end

project = Xcodeproj::Project.open(project_path)
target  = project.targets.find { |t| t.product_type == 'com.apple.product-type.application' }

target.build_configurations.each do |config|
  old = config.build_settings['INFOPLIST_FILE']
  config.build_settings['INFOPLIST_FILE'] = '$(SRCROOT)/Info.plist'
  puts "  #{config.name}: #{old} → $(SRCROOT)/Info.plist"
end

project.save
puts "\n✓ INFOPLIST_FILE 已更新，请 ⌘⇧K 清理后再 ⌘B 编译"
