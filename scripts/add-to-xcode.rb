#!/usr/bin/env ruby
# scripts/add-to-xcode.rb
# 把 AnnuliSwift/ 里新增的 Swift 文件自动加入 Xcode 项目（防重复）

begin
  require 'xcodeproj'
rescue LoadError
  puts "  缺少依赖，请先运行: gem install xcodeproj"
  exit 1
end

require 'set'
require 'pathname'

project_path  = ARGV[0]
xcode_src_dir = ARGV[1]
swift_src_dir = ARGV[2]

project = Xcodeproj::Project.open(project_path)
target  = project.targets.find { |t| t.product_type == 'com.apple.product-type.application' }

# ── 步骤 1：清除编译阶段中的重复条目 ──────────────────────────────
compile_phase = target.source_build_phase
seen_uuids = Set.new
dups = []
compile_phase.files.each do |bf|
  if seen_uuids.include?(bf.file_ref&.uuid)
    dups << bf
  else
    seen_uuids << bf.file_ref&.uuid
  end
end
if dups.any?
  puts "  清除 #{dups.size} 个重复编译条目"
  dups.each { |bf| compile_phase.remove_build_file(bf) }
end

# ── 步骤 2：收集已有文件引用（用 uuid 和 basename 双重索引）─────────
existing_uuids     = Set.new(project.files.map(&:uuid))
existing_basenames = Set.new(project.files.map { |f| File.basename(f.path.to_s) })

# 编译阶段已有的 file_ref uuid
compiled_uuids = Set.new(compile_phase.files.map { |bf| bf.file_ref&.uuid })

# ── 步骤 3：确保所有已有文件引用都在编译阶段 ──────────────────────
project.files.each do |file_ref|
  next unless file_ref.path.to_s.end_with?('.swift')
  unless compiled_uuids.include?(file_ref.uuid)
    compile_phase.add_file_reference(file_ref)
    compiled_uuids << file_ref.uuid
    puts "  (补加编译) #{File.basename(file_ref.path.to_s)}"
  end
end

# ── 步骤 4：添加真正新增的文件 ─────────────────────────────────────
new_count = 0

Dir.glob("#{swift_src_dir}/**/*.swift").sort.each do |swift_path|
  filename = File.basename(swift_path)
  next if existing_basenames.include?(filename)

  rel   = Pathname.new(swift_path).relative_path_from(Pathname.new(swift_src_dir)).to_s
  parts = rel.split('/')

  root_group = project.main_group.groups.find { |g| g.name == 'Annuli' || g.path == 'Annuli' }
  root_group ||= project.main_group

  group = root_group
  parts[0..-2].each do |folder|
    sub   = group.groups.find { |g| g.name == folder || g.path == folder }
    group = sub || group.new_group(folder, folder)
  end

  file_ref = group.new_reference(filename)
  compile_phase.add_file_reference(file_ref)
  existing_basenames << filename

  puts "  + #{rel}"
  new_count += 1
end

project.save

if new_count > 0
  puts "  已添加 #{new_count} 个新文件"
elsif dups.empty?
  puts "  无变更"
end
