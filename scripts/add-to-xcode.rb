#!/usr/bin/env ruby
# scripts/add-to-xcode.rb
# 把 AnnuliSwift/ 里新增的 Swift 文件自动加入 Xcode 项目

begin
  require 'xcodeproj'
rescue LoadError
  puts "  缺少依赖，请先运行: gem install xcodeproj"
  exit 1
end

require 'set'
require 'pathname'

project_path = ARGV[0]
xcode_src_dir = ARGV[1]
swift_src_dir  = ARGV[2]

project = Xcodeproj::Project.open(project_path)
target  = project.targets.find { |t| t.product_type == 'com.apple.product-type.application' }

# 收集项目中已有的文件名
existing_names = Set.new
project.files.each { |f| existing_names << File.basename(f.path.to_s) }

new_count = 0

Dir.glob("#{swift_src_dir}/**/*.swift").sort.each do |swift_path|
  filename = File.basename(swift_path)
  next if existing_names.include?(filename)

  # 相对于 AnnuliSwift/ 的路径，如 "Views/Shared/SettingsView.swift"
  rel = Pathname.new(swift_path).relative_path_from(Pathname.new(swift_src_dir)).to_s
  parts = rel.split('/')   # ["Views", "Shared", "SettingsView.swift"]

  # 找到 Xcode 项目里的根分组（通常叫 Annuli）
  root_group = project.main_group.groups.find { |g| g.name == 'Annuli' || g.path == 'Annuli' }
  root_group ||= project.main_group

  # 按目录层级找到或创建对应分组
  group = root_group
  parts[0..-2].each do |folder|
    sub = group.groups.find { |g| g.name == folder || g.path == folder }
    group = sub || group.new_group(folder, folder)
  end

  # 添加文件引用并加入编译目标
  file_ref = group.new_reference(filename)
  target.source_build_phase.add_file_reference(file_ref)

  puts "  + #{rel}"
  new_count += 1
end

if new_count > 0
  project.save
  puts "  已添加 #{new_count} 个新文件"
else
  puts "  无新文件"
end
