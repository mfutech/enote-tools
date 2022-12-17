#
# A simple Evernote API demo script that lists all notebooks in the user's
# account and creates a simple test note in the default notebook.
#
# Before running this sample, you must:
# - fill in your Evernote developer token.
# - install evernote-thrift gem.
#
# To run (Unix):
#   ruby EDAMTest.rb
#

DIR = __dir__
$LOAD_PATH.unshift DIR

require "digest/md5"
require 'evernote-thrift'
require 'config/auth.rb'


unless authToken
    puts "Error: no authtenciation token"
    exit(1)
end

# Initial development is performed on our sandbox server. To use the production
# service, change "sandbox.evernote.com" to "www.evernote.com" and replace your
# developer token above with a token from
# https://www.evernote.com/api/DeveloperToken.action
evernoteHost = "sandbox.evernote.com"
userStoreUrl = "https://#{evernoteHost}/edam/user"

userStoreTransport = Thrift::HTTPClientTransport.new(userStoreUrl)
userStoreProtocol = Thrift::BinaryProtocol.new(userStoreTransport)
userStore = Evernote::EDAM::UserStore::UserStore::Client.new(userStoreProtocol)

versionOK = userStore.checkVersion("Evernote EDAMTest (Ruby)",
				   Evernote::EDAM::UserStore::EDAM_VERSION_MAJOR,
				   Evernote::EDAM::UserStore::EDAM_VERSION_MINOR)
puts "Is my Evernote API version up to date?  #{versionOK}"
puts
exit(1) unless versionOK

# Get the URL used to interact with the contents of the user's account
# When your application authenticates using OAuth, the NoteStore URL will
# be returned along with the auth token in the final OAuth request.
# In that case, you don't need to make this call.
noteStoreUrl = userStore.getNoteStoreUrl(authToken)

noteStoreTransport = Thrift::HTTPClientTransport.new(noteStoreUrl)
noteStoreProtocol = Thrift::BinaryProtocol.new(noteStoreTransport)
noteStore = Evernote::EDAM::NoteStore::NoteStore::Client.new(noteStoreProtocol)

# List all of the notebooks in the user's account
notebooks = noteStore.listNotebooks(authToken)
puts "Found #{notebooks.size} notebooks:"
defaultNotebook = notebooks.first
notebooks.each do |notebook|
  puts "  * #{notebook.name}"
end

puts
puts "Creating a new note in the default notebook: #{defaultNotebook.name}"
puts

# To create a new note, simply create a new Note object and fill in
# attributes such as the note's title.
note = Evernote::EDAM::Type::Note.new
note.title = "Test note from EDAMTest.rb"


# The content of an Evernote note is represented using Evernote Markup Language
# (ENML). The full ENML specification can be found in the Evernote API Overview
# at http://dev.evernote.com/documentation/cloud/chapters/ENML.php
note.content = <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE en-note SYSTEM "http://xml.evernote.com/pub/enml2.dtd">
<en-note>Here is the Evernote logo:<br/>
</en-note>
EOF

# Finally, send the new note to Evernote using the createNote method
# The new Note object that is returned will contain server-generated
# attributes such as the new note's unique GUID.
createdNote = noteStore.createNote(authToken, note)

puts "Successfully created a new note with GUID: #{createdNote.guid}"
