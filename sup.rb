#!/usr/bin/env ruby
#
# PDFや画像をS3とかにアップロードしつつScrapboxに登録する
# Gyazoにも登録する
#
# S3とかへのアップロードは upload コマンド
# Gyazoへのアップロードは upload_gyazo
#
# Scrapboxにページを作らない場合は -n オプション
#

require 'gyazo'
require 'digest/md5'

make_scrapbox_page = true
if ARGV[0] == "-n"
  make_scrapbox_page = false
  ARGV.shift
end

file = ARGV[0]
gyazourl = ARGV[1]
gyazourl =~ /[0-9a-f]{32}/
gyazoid = $&

if !file || (gyazourl && !gyazoid)
  STDERR.puts "% sup document [GyazoURL]"
  exit
end

gyazo_token = ENV['GYAZO_TOKEN'] # .bash_profileに書いておく
gyazo = Gyazo::Client.new access_token: gyazo_token

project = "masui-files" # Scrapboxプロジェクト名

if `which open` != ""
  open = "open"
elsif `which xdg-open` != ""
  open = "xdg-open"
else
  STDERR.puts "open command not found"
  exit
end

exit unless File.exist?(file)

hash = Digest::MD5.new.update(File.read(file)).to_s
if file =~ /^.*(\.\w+)$/ then
  ext = $1
end

# S3にアップロード
STDERR.puts "upload '#{file}'"
s3url = `upload '#{file}'`.chomp
STDERR.puts s3url

tmpimage = nil
if gyazourl
  # 既に登録されているGyazo画像を利用
  #
  # 登録されてるGyazoデータを取得
  #
  res = gyazo.image image_id: gyazoid
  url = "https://gyazo.com/#{gyazoid}.#{res[:type]}"
  tmpimage = "/tmp/tmpimage#{$$}.#{res[:type]}"
  cmd = "wget -q #{url} -O #{tmpimage}"
  system cmd
  #
  # Gyazo.comのデータ削除
  #
  gyazo.delete image_id: gyazoid
end

# Gyazoにアップロード
STDERR.puts "upload_gyazo '#{tmpimage}' #{s3url}"
gyazourl = `upload_gyazo '#{tmpimage}' #{s3url}`.chomp

if make_scrapbox_page
  # Scrapboxページ作成
  title = Time.now.strftime('%Y%m%d%H%M%S')
  scrapboxurl = "http://scrapbox.io/#{project}/#{title}?body=[#{s3url} #{gyazourl}]%0d"
  system "#{open} '#{scrapboxurl}'"
end

File.delete tmpimage if tmpimage
