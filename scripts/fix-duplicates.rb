#!/usr/bin/env ruby
# scripts/fix-duplicates.rb
# 1) 按文件名去重编译条目
# 2) 从编译阶段移除 Package.swift（不应被编译为 app 源码）

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
changed = false

# ── 1. 移除 Package.swift（SPM 清单文件，不应参与 app 编译）──────────
pkg_entries = phase.files.select { |bf| File.basename(bf.file_ref&.path.to_s) == 'Package.swift' }
if pkg_entries.any?
  puts "移除 Package.swift 出编译阶段..."
  pkg_entries.each do |bf|
    puts "  - #{bf.file_ref&.path}"
    phase.files.delete(bf)
  end
  changed = true
end

# ── 2. 按 basename 去重 ──────────────────────────────────────────────
by_name = Hash.new { |h, k| h[k] = [] }
phase.files.each do |bf|
  path = bf.file_ref&.path.to_s
  next if path.empty?
  by_name[File.basename(path)] << bf
end

by_name.each do |name, bfs|
  next if bfs.size <= 1
  puts "重复: #{name}"
  keeper = bfs.find { |bf| !bf.file_ref&.path.to_s.include?('AnnuliSwift') } || bfs.first
  (bfs - [keeper]).each do |bf|
    puts "  移除: #{bf.file_ref&.path}"
    phase.files.delete(bf)
    changed = true
  end
end

if changed
  project.save
  puts "\n✓ 已保存。请在 Xcode 执行 Product → Clean Build Folder (⌘⇧K)，再 ⌘B 编译。"
else
  puts "✓ 无需修复"
end
