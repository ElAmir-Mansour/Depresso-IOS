require 'xcodeproj'
project_path = 'Depresso.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'Depresso' }

def add_file(project, target, path)
  file_name = File.basename(path)
  group_path = File.dirname(path)
  
  # Find or create groups
  current_group = project.main_group
  group_path.split('/').each do |name|
    next if name == '.' || name == 'Depresso' # Skip root or project name if redundant
    current_group = current_group.find_subgroup(name) || current_group.new_group(name)
  end
  
  # Add file if not exists
  file_ref = current_group.files.find { |f| f.path == file_name }
  unless file_ref
    file_ref = current_group.new_file(path)
    target.add_file_references([file_ref])
    puts "Added #{path} to project and target."
  else
    puts "#{path} already exists in project."
  end
end

add_file(project, target, 'Features/Wellness/BreathingFeature.swift')
add_file(project, target, 'Features/Journal/GuidedJournalFeature.swift')

project.save
