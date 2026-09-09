#!/usr/bin/env ruby
# scripts/fix-duplicates.rb
# 清理 Xcode 编译阶段里同文件名但不同路径的重复条目

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
phase   = target.source_build_phase

# 按文件名（basename）分组，找出重名的条目
by_name = Hash.new { |h, k| h[k] = [] }
phase.files.each do |bf|
  path = bf.file_ref&.path.to_s
  next if path.empty?
  by_name[File.basename(path)] << bf
end

# 只保留每个文件名里路径包含 "Annuli/Annuli" 或最短的那一个，其余删除
to_remove = []
by_name.each do |name, bfs|
  next if bfs.size <= 1
  puts "  重复: #{name} (#{bfs.size} 份)"
  bfs.each { |bf| puts "         #{bf.file_ref&.path}" }

  # 优先保留路径里不含 AnnuliSwift 的（即 Annuli/Annuli/ 目录下的正式文件）
  keeper = bfs.find { |bf| !bf.file_ref&.path.to_s.include?('AnnuliSwift') } || bfs.first
  to_remove.concat(bfs - [keeper])
end

if to_remove.empty?
  puts "✓ 没有发现重复条目（按文件名检查）"
else
  puts "\n移除 #{to_remove.size} 个重复条目..."
  to_remove.each do |bf|
    puts "  - #{bf.file_ref&.path}"
    phase.files.delete(bf)
  end
  project.save
  puts "\n✓ 已保存。请在 Xcode 执行 Product → Clean Build Folder (⌘⇧K)，再 ⌘B 编译。"
end
