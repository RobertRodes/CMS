ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'rack/test'
require 'fileutils'

require_relative '../cms'

class AppTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup
    FileUtils.mkdir_p(data_path)
    create_document "about.md", "# It's all about me."
    create_document "changes.txt"
    create_document "history.txt", "I'm a fascinating guy."
  end

  def teardown
    FileUtils.rm_rf(data_path)
  end

  def session
    last_request.env["rack.session"]
  end

  def admin_session
    {"rack.session" => { username: "admin" } }
  end

  def create_document(name, content = "")
    File.open(File.join(data_path, name), "w") do |file|
      file.write(content)
    end
  end

  def test_index
    get '/'
    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, "about.md" 
    assert_includes last_response.body, "changes.txt" 
    assert_includes last_response.body, "history.txt" 
  end

  def test_history
    get '/history.txt'
    assert_equal 200, last_response.status
    assert_equal 'text/plain', last_response['Content-Type']
    assert_includes last_response.body, 'fascinating guy'
  end

  def test_viewing_markdown_document
    get "/about.md"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "about me.</h1>"
  end

   def test_editing_document
    get "/changes.txt/edit", {}, admin_session

    assert_equal 200, last_response.status
    assert_includes last_response.body, "<textarea"
    assert_includes last_response.body, %q(<input type="submit")
  end

  def test_document_not_found
    get '/badfile.txt'

    assert_equal 302, last_response.status
    assert_equal "File 'badfile.txt' not found.", session[:message]
  end

  def test_updating_document
    post "/changes.txt/edit", {text: "new content"}, admin_session

    assert_equal 302, last_response.status
    assert_equal "Changes to 'changes.txt' saved.", session[:message]

    get "/changes.txt"

    assert_equal 200, last_response.status
    assert_includes last_response.body, "new content"
  end

  def test_view_new_document_form
    get "/new", {}, admin_session

    assert_equal 200, last_response.status
    assert_includes last_response.body, %q(<input type="text")
    assert_includes last_response.body, %q(<input type="submit")
  end

  def test_create_new_document
    post "/create", {file_name: "test.txt"}, admin_session 
    assert_equal 302, last_response.status

    assert_equal "New file 'test.txt' created.", session[:message]

    get "/"
    assert_includes last_response.body, "test.txt"
  end

  def test_create_new_document_without_filename
    post "/create", {file_name: ""}, admin_session
    assert_equal 422, last_response.status

    assert_includes last_response.body, "Please enter a file name or cancel."
  end

  def test_deleting_document
    create_document("test.txt")

    post "/test.txt/delete", {}, admin_session
    assert_equal 302, last_response.status
    assert_equal "File 'test.txt' deleted.", session[:message]

    get "/"
    refute_includes last_response.body, %q(href="/test.txt")
  end

  def test_signin_form
    get "/users/signin"

    assert_equal 200, last_response.status
    assert_includes last_response.body, "<input"
    assert_includes last_response.body, %q(<button type="submit")
  end

  def test_signin
    post "/users/signin", username: "admin", password: "secret"
    assert_equal 302, last_response.status

    assert_equal "Welcome!", session[:message]
    assert_equal "admin", session[:username]
  end

  def test_signin_with_bad_credentials
    post "/users/signin", username: "guest", password: "shhhh"
    assert_equal 422, last_response.status
    assert_nil session[:username]
    assert_includes last_response.body, "Invalid credentials"
  end

  def test_signout
    get "/", {}, admin_session
    assert_includes last_response.body, "Signed in as 'admin'."

    post "/users/signout"
    assert_equal "User 'admin' signed out.", session[:message]

    get last_response['Location']
    assert_nil session[:username]
    assert_includes last_response.body, 'Sign In'
  end

  # Tests for unauthorized behavior while signed out

  def test_view_edit_while_signed_out
    create_document('test.txt')
    get '/test.txt/edit'
    assert_equal 302, last_response.status
    assert_equal 'You must be signed in to do that.', session[:message]
  end

  def test_save_edit_while_signed_out
    create_document('test.txt')

    post '/test.txt/edit'
    assert_equal 302, last_response.status
    assert_equal 'You must be signed in to do that.', session[:message]
  end

  def test_new_while_signed_out
    get '/new'
    assert_equal 302, last_response.status
    assert_equal 'You must be signed in to do that.', session[:message]
  end

  def test_create_while_signed_out
    post '/create', { file_name: 'test.txt'}
    assert_equal 302, last_response.status
    assert_equal 'You must be signed in to do that.', session[:message]
  end

  def test_delete_while_signed_out
    create_document('test.txt')

    post '/test.txt/delete'
    assert_equal 302, last_response.status
    assert_equal 'You must be signed in to do that.', session[:message]
  end
end