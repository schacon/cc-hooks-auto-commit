#!/usr/bin/env ruby

require 'json'
require 'tempfile'

# Read JSON from STDIN
input = STDIN.read
data = JSON.parse(input)

# Extract required fields
session_id = data['session_id']
cwd = data['cwd']
transcript_path = data['transcript_path']

# Change directory to the cwd
Dir.chdir(cwd)

# Read all entries and find the last user message with string content (same as post_chat.rb)
last_user_entry = File.foreach(transcript_path)
  .map { |line| JSON.parse(line.strip) }
  .reverse
  .find { |entry| entry.dig('message', 'role') == 'user' && entry.dig('message', 'content').is_a?(String) }

# Extract message content from the last user entry
message_content = last_user_entry&.dig('message', 'content')

# Exit if no message content found
exit 1 unless message_content

# Create branch name
branch_ref = "refs/heads/claude/#{session_id}"

# Construct paths
index_dir = File.join(cwd, '.git', 'claude', 'indexes', session_id)
index_file = File.join(index_dir, 'index')
base_commit_file = File.join(index_dir, 'base_commit')

# Determine parent commit
parent_commit = nil

# Check if the branch exists
branch_exists = system("git show-ref --verify --quiet #{branch_ref}")

if branch_exists
  # Use the commit that the branch points to
  parent_commit = `git rev-parse #{branch_ref}`.strip
else
  # Use the base_commit file contents
  if File.exist?(base_commit_file)
    parent_commit = File.read(base_commit_file).strip
  else
    # Fallback to HEAD if base_commit file doesn't exist
    parent_commit = `git rev-parse HEAD`.strip
  end
end

# Create commit tree from the session index
if File.exist?(index_file)
  # Write the index tree
  tree_sha = `GIT_INDEX_FILE=#{index_file} git write-tree`.strip

  # Create temporary file with the message content
  temp_file = Tempfile.new('commit_message')
  begin
    temp_file.write(message_content)
    temp_file.close

    # Create commit using git commit-tree
    commit_sha = `git commit-tree #{tree_sha} -p #{parent_commit} -F #{temp_file.path}`.strip

    # Update the ref to point to the new commit
    system("git update-ref #{branch_ref} #{commit_sha}")
  ensure
    temp_file.unlink
  end
else
  exit 1
end
