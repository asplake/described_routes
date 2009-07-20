require 'test/test_helper'

class DescribedRoutesRunTimeTest < ActionController::IntegrationTest
  def test_root_headers
    get "/"
    assert_equal(
      '<http://www.example.com/>; rel="self"; role="http://www.example.com/described_routes#root", ' +
      '<http://www.example.com/described_routes>; rel="describedby"; meta="ResourceTemplates", ' +
      '<http://www.example.com/admin/products>; rel="http://www.example.com/described_routes#admin_products"; role="http://www.example.com/described_routes#admin_products", ' +
      '<http://www.example.com/described_routes>; rel="http://www.example.com/described_routes#described_routes"; role="http://www.example.com/described_routes#described_routes", ' +
      '<http://www.example.com/pages>; rel="http://www.example.com/described_routes#pages"; role="http://www.example.com/described_routes#pages", ' +
      '<http://www.example.com/users>; rel="http://www.example.com/described_routes#users"; role="http://www.example.com/described_routes#users"',
      headers["Link"])
  end

  def test_users_headers
    get "/users"
    assert_equal(
      '<http://www.example.com/users>; rel="self"; role="http://www.example.com/described_routes#users", ' +
      '<http://www.example.com/described_routes/users>; rel="describedby"; meta="ResourceTemplate", ' +
      '<http://www.example.com/>; rel="up"; role="http://www.example.com/described_routes#root", ' +
      '<http://www.example.com/users/new>; rel="http://www.example.com/described_routes/users#new_user"; role="http://www.example.com/described_routes#new_user"',
      headers["Link"])
  end

  def test_new_user_headers
    get "/users/new"
    assert_equal(
      '<http://www.example.com/users/new>; rel="self"; role="http://www.example.com/described_routes#new_user", ' +
      '<http://www.example.com/described_routes/new_user>; rel="describedby"; meta="ResourceTemplate", ' +
      '<http://www.example.com/users>; rel="up"; role="http://www.example.com/described_routes#users"',
      headers["Link"])
  end

  def test_user_headers
    get "/users/dojo"
    assert_equal(
      '<http://www.example.com/users/dojo>; rel="self"; role="http://www.example.com/described_routes#user", ' +
      '<http://www.example.com/described_routes/user?user_id=dojo>; rel="describedby"; meta="ResourceTemplate", ' +
      '<http://www.example.com/users>; rel="up"; role="http://www.example.com/described_routes#users", ' +
      '<http://www.example.com/users/dojo/edit>; rel="edit"; rel="http://www.example.com/described_routes/user#edit"; role="http://www.example.com/described_routes#edit_user", ' +
      '<http://www.example.com/users/dojo/articles>; rel="http://www.example.com/described_routes/user#articles"; role="http://www.example.com/described_routes#user_articles", ' +
      '<http://www.example.com/users/dojo/profile>; rel="http://www.example.com/described_routes/user#profile"; role="http://www.example.com/described_routes#user_profile"',
      headers["Link"])
  end

  def test_edit_user_headers
    get "/users/dojo/edit"
    assert_equal(
      '<http://www.example.com/users/dojo/edit>; rel="self"; role="http://www.example.com/described_routes#edit_user", ' +
      '<http://www.example.com/described_routes/edit_user?user_id=dojo>; rel="describedby"; meta="ResourceTemplate", ' +
      '<http://www.example.com/users/dojo>; rel="up"; role="http://www.example.com/described_routes#user"',
      headers["Link"])
  end

end
