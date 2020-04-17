#!/usr/bin/env ruby
#
# PDFや画像をS3とかにアップロードしつつScrapboxに登録する
# Gyazoにも登録する
#
# S3とかへのアップロードは upload コマンド
# Gyazoへのアップロードは upload_gyazo
#

project = "masui-files" # Scrapboxプロジェクト名

require 'digest/md5'

if `which open` != ""
  open = "open"
elsif `which xdg-open` != ""
  open = "xdg-open"
else
  STDERR.puts "open command not found"
  exit
end

ARGV.each { |file|
  exit unless File.exist?(file)

  hash = Digest::MD5.new.update(File.read(file)).to_s
  if file =~ /^.*(\.\w+)$/ then
    ext = $1
  end
    
  urls = []
  
  # S3などにアップロード
  STDERR.puts "upload '#{file}'"
  s3url = `upload '#{file}'`.chomp
  STDERR.puts s3url
  urls << s3url

  # Gyazoにアップロード
  STDERR.puts "upload_gyazo '#{file}'"
  gyazourl = `upload_gyazo '#{file}'`.chomp
  if gyazourl != ''
    STDERR.puts gyazourl
    urls << gyazourl
  end

  title = Time.now.strftime('%Y%m%d%H%M%S')

  scrapboxurl = "http://scrapbox.io/#{project}/#{title}?body=[#{urls.join(' ')}]%0d"

  # Scrapboxページ作成
  system "#{open} '#{scrapboxurl}'"
}
