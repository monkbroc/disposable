require 'test_helper'

class TwinCollectionTest < MiniTest::Spec
  module Model
    Song  = Struct.new(:id, :title, :album)
    Album = Struct.new(:id, :name, :songs)
  end


  module Twin
    class Album < Disposable::Twin
      property :id # DISCUSS: needed for #save.
      property :name
      collection :songs, :twin => lambda { |*| Song }

      # model Model::Album
    end

    class Song < Disposable::Twin
      property :id # DISCUSS: needed for #save.
      property :name, :as => :title
      property :album, :twin => Album

      # model Model::Song
    end
  end

  let (:song) { Model::Song.new(1, "Broken", nil) }
  let (:album) { Model::Album.new(1, "The Rest Is Silence", [song]) }

  describe "reader for collection" do
    it do
      twin = Twin::Album.new(album)

      twin.songs.size.must_equal 1
      twin.songs[0].title.must_equal "Broken"
      twin.songs.must_be_instance_of Disposable::Twin::Collection

    end
  end
end

# ActiveRecord::Schema.define do
#   create_table :artists do |table|
#     table.column :name, :string
#     table.timestamps
#   end
#   create_table :songs do |table|
#     table.column :title, :string
#     table.column :artist_id, :integer
#     table.column :album_id, :integer
#     table.timestamps
#   end
#   create_table :albums do |table|
#     table.column :name, :string
#     table.timestamps
#   end
# end
# Artist.new(:name => "Racer X").save

require "disposable/twin/sync"
require "disposable/twin/save"

class TwinCollectionActiveRecordTest < MiniTest::Spec
  module Twin
    class Album < Disposable::Twin
      property :id # DISCUSS: needed for #save.
      property :name
      collection :songs, :twin => lambda { |*| Song }

      # model Model::Album

      extend Representer
      include Sync
      include Save
    end

    class Song < Disposable::Twin
      property :id # DISCUSS: needed for #save.
      property :title

      # property :persisted?, readonly: true # TODO: implement that!!!! for #sync

      # model Model::Song

      extend Representer
      include Sync
      include Save
    end
  end

  let (:album) { Album.create(name: "The Rest Is Silence") }
  let (:song1) { Song.new(title: "Snorty Pacifical Rascal") } # unsaved.

  it do
    twin = Twin::Album.new(album)
    # TODO: test all writers.
    twin.songs << song1 # assuming that we add AR model here.
    twin.songs[0].must_be_instance_of Twin::Song
    # twin.songs[0].persisted?.must_equal false
    twin.songs[0].send(:model).persisted?.must_equal false

    album.songs.size.must_equal 0 # nothing synced, yet.

    # sync: delete removed items, add new?

    # save
    twin.save

    album.persisted?.must_equal true
    album.name.must_equal "The Rest Is Silence"

    album.songs.size.must_equal 1 # synced!
    album.songs.first.persisted?.must_equal true
  end
end