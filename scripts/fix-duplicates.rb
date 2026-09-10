#!/usr/bin/env ruby
# scripts/fix-duplicates.rb
# 1) 移除指向 Annuli/Annuli/ 的错误路径引用（旧 rsync 遗留）
# 2) 按文件名去重编译条目
# 3) 从编译阶段移除 Package.swift

begin
  require 'xcodeproj'
rescue LoadError
  puts "请先运行: gem install xcodeproj"
  exit 1
end

require 'pathname'

project_path = ARGV[0]
unless project_path
  puts "用法: ruby fix-duplicates.rb <path/to/Annuli.xcodeproj>"
  exit 1
end

project = Xcodeproj::Project.open(project_path)
target  = project.targets.find { |t| t.product_type == 'com.apple.product-type.application' }
phase   = target.source_build_phase
changed = false

# ── 0. 移除 Package.swift（SPM 清单文件，不应参与 app 编译）──────────
pkg_entries = phase.files.select { |bf| File.basename(bf.file_ref&.path.to_s) == 'Package.swift' }
if pkg_entries.any?
  puts "移除 Package.swift 出编译阶段..."
  pkg_entries.each { |bf| phase.files.delete(bf) }
  changed = true
end

pkg_refs = project.files.select { |f| File.basename(f.path.to_s) == 'Package.swift' }
if pkg_refs.any?
  puts "从项目中移除 Package.swift 文件引用..."
  pkg_refs.each { |f| f.remove_from_project }
  changed = true
end

# ── 1. 移除指向 /Annuli/Annuli/ 路径的错误文件引用（旧 rsync 遗留）──
proj_dir = Pathname.new(project_path).dirname.expand_path
bad_refs = project.files.select do |f|
  begin
    real = f.real_path
    real.to_s.include?('/Annuli/Annuli/')
  rescue
    false
  end
end
if bad_refs.any?
  puts "移除指向 Annuli/Annuli/ 的错误路径引用（共 #{bad_refs.size} 个）..."
  bad_refs.each do |f|
    puts "  - #{f.real_path rescue f.path}"
    # 先从编译阶段移除对应 build file
    phase.files.select { |bf| bf.file_ref&.uuid == f.uuid }.each { |bf| phase.files.delete(bf) }
    f.remove_from_project
  end
  changed = true
end

# ── 2. 按 basename 去重编译条目 ─────────────────────────────────────
by_name = Hash.new { |h, k| h[k] = [] }
phase.files.each do |bf|
  path = bf.file_ref&.path.to_s
  next if path.empty?
  by_name[File.basename(path)] << bf
end

by_name.each do |name, bfs|
  next if bfs.size <= 1
  puts "重复: #{name}"
  # 优先保留 real_path 不含 /Annuli/Annuli/ 的（即正确位置）
  keeper = bfs.find { |bf|
    begin; !bf.file_ref.real_path.to_s.include?('/Annuli/Annuli/'); rescue; false; end
  } || bfs.first
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
