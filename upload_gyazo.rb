#!/usr/bin/env ruby
#
# PDFやJPEGなどをGyazoにアップロードする
#
# JPEGの場合はタイムスタンプを保持する
# 古い画像の場合は作成時刻を利用するべきだろうか?
#

require 'exifr/jpeg'
require 'gyazo'

gyazo_token = ENV['GYAZO_TOKEN'] # .bash_profileに書いておく
gyazo = Gyazo::Client.new access_token: gyazo_token

urls = []
ARGV.each { |file|
  if File.exist?(file)
    t = File.mtime(file)
    if file =~ /\.pdf$/i
      # 画像にしてGyazoにアップロード
      STDERR.puts "upload #{file} to Gyazo..."
      system "convert -density 300 '#{file}[0]' /tmp/upload_gyazo.png"
      res = gyazo.upload imagefile: '/tmp/upload_gyazo.png', created_at: t
      urls << res[:permalink_url]
      sleep 1
    elsif file =~ /\.(jpg|jpeg)$/i
      # JPEG
      STDERR.puts "upload #{file} to Gyazo..."
      # t = Time.now
      begin
        exif = EXIFR::JPEG.new(file)
        t = exif.date_time if exif.date_time.to_s != ''
      rescue
      end
      res = gyazo.upload imagefile: file, created_at: t
      urls << res[:permalink_url]
      sleep 1
    elsif file =~ /\.(gif|png)$/i
      # その他の画像
      STDERR.puts "upload #{file} to Gyazo..."
      res = gyazo.upload imagefile: file, created_at: t
      urls << res[:permalink_url]
      sleep 1
    end
  end
}

urls.each { |url|
  puts url
}



