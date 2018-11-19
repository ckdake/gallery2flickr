require 'flickraw'

FlickRaw.api_key=""
FlickRaw.shared_secret=""

# token = flickr.get_request_token
# auth_url = flickr.get_authorize_url(token['oauth_token'], :perms => 'delete')
#
# puts "Open this url in your process to complete the authication process : #{auth_url}"
# puts "Copy here the number given when you complete the process."
# verify = gets.strip
#
# begin
#   flickr.get_access_token(token['oauth_token'], token['oauth_token_secret'], verify)
#   login = flickr.test.login
#   puts "You are now authenticated as #{login.username} with token #{flickr.access_token} and secret #{flickr.access_secret}"
# rescue FlickRaw::FailedResponse => e
#   puts "Authentication failed : #{e.msg}"
# end

flickr.access_token=""
flickr.access_secret=""

@photosets = {}

def refresh_photosets
  @photosets = flickr.photosets.getList
end

def upload_image_to_set(file, set)
  puts "COPY: #{file} to #{set}"
  if flickr.photos.search(user_id: 'me', tags: "g2migrated", text: file).count > 0
    puts "-already uploaded"
  else
    photo_id = flickr.upload_photo file,
      description: file,
      tags: 'g2migrated',
      is_public: 0
    if the_set = @photosets.find { |ps| ps.title == set }
      puts "Existing set: #{set}"
      flickr.photosets.addPhoto(photoset_id: the_set.id, photo_id: photo_id)
    else
      puts "New set: #{set}"
      flickr.photosets.create(title: set, primary_photo_id: photo_id)
      refresh_photosets
    end
  end
end

# g2data specific
def import_album(album_path, name)
  Dir.entries(album_path).each do |f|
    if f != '.' && f != '..'
      if File.directory?("#{album_path}/#{f}")
        import_album("#{album_path}/#{f}", f)
      else
        upload_image_to_set("#{album_path}/#{f}","#{album_path}".gsub('/','-'))
      end
    end
  end
end

def import(albums_path)
  Dir.entries(albums_path).each do |f|
    if f != '.' && f != '..'
      import_album(albums_path + f, f)
    end
  end
end

refresh_photosets
import('albums/')
