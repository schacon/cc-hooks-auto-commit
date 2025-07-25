#!/usr/bin/env ruby

require 'json'
require 'fileutils'

# Read JSON from STDIN
input = STDIN.read
data = JSON.parse(input)

# Extract required fields
session_id = data['session_id']
cwd = data['cwd']

# Change directory to the cwd
Dir.chdir(cwd)

# Ensure .git directory exists
git_dir = File.join(cwd, '.git')
exit 1 unless Dir.exist?(git_dir)

# Create log entry with timestamp
log_entry = {
  timestamp: Time.now.iso8601,
  session_id: session_id,
  event: 'subagent_stop',
  data: data
}

# Append to .git/subagent.jsonl
log_file = File.join(git_dir, 'subagent.jsonl')
File.open(log_file, 'a') do |file|
  file.puts(log_entry.to_json)
end