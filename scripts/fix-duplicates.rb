#!/usr/bin/env ruby
# scripts/fix-duplicates.rb
# 一次性清理 Xcode 项目编译阶段的重复条目

begin
  require 'xcodeproj'
rescue LoadError
  puts "请先运行: gem install xcodeproj"
  exit 1
end

project_path = ARGV[0]
unless project_path
  puts "用法: ruby fix-duplicates.rb <path/to/Annuli.xcodeproj>"
  exit 1
end

project = Xcodeproj::Project.open(project_path)
target  = project.targets.find { |t| t.product_type == 'com.apple.product-type.application' }

phase = target.source_build_phase

# 以 file_ref.uuid 为 key 找出重复
seen   = {}
to_remove = []

phase.files.each do |bf|
  uuid = bf.file_ref&.uuid
  next unless uuid
  if seen[uuid]
    to_remove << bf
  else
    seen[uuid] = bf
  end
end

if to_remove.empty?
  puts "✓ 没有发现重复条目，无需修复"
else
  puts "发现 #{to_remove.size} 个重复条目，正在清理..."
  to_remove.each do |bf|
    name = bf.file_ref&.path || "(unknown)"
    phase.files.delete(bf)
    puts "  移除: #{name}"
  end
  project.save
  puts "✓ 已保存。请在 Xcode 里执行 Product → Clean Build Folder (⌘⇧K)，再编译。"
end
