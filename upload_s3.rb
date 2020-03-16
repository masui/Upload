#!/usr/bin/env ruby
#
# ファイルをS3にアップロード (増井専用)
#

bucket = "masui.org"
project = "masui-files"

require 'digest/md5'
require 'shellwords'

if `which pbcopy` != ""
  pbcopy = "pbcopy"
elsif `which xsel` != ""
  pbcopy = "xsel --clipboard --input"
else
  STDERR.puts "pbcopy command not found"
  exit
end

file = ARGV.shift
unless file && File.exist?(file)
  STDERR.puts "Upload a file to S3"
  STDERR.puts "% upload file"
  exit
end

home = ENV['HOME']

ext = ''
if file =~ /^(.*)(\.\w+)$/ then
  ext = $2
end

hash = Digest::MD5.new.update(File.read(file)).to_s

dstfile = "s3://#{bucket}/#{hash[0]}/#{hash[1]}/#{hash}#{ext}"
STDERR.puts "s3cmd -c #{home}/.s3cfg put --acl-public #{Shellwords.escape(file)} #{dstfile} > /dev/null 2> /dev/null"
system "s3cmd -c #{home}/.s3cfg put --acl-public #{Shellwords.escape(file)} #{dstfile} > /dev/null 2> /dev/null"
system "echo http://#{bucket}.s3.amazonaws.com/#{hash[0]}/#{hash[1]}/#{hash}#{ext} | #{pbcopy}"
puts "http://#{bucket}.s3.amazonaws.com/#{hash[0]}/#{hash[1]}/#{hash}#{ext}"
