require 'test/test_helper'

class DescribedRoutesRunTimeTest < ActionController::IntegrationTest
  def test_root_headers
    get "/"
    assert_equal(
      '<http://www.example.com/>; rel="self"; type="http://www.example.com/described_routes#root", ' +
      '<http://www.example.com/described_routes>; rel="describedby"; type="http://www.example.com/described_routes#ResourceTemplate", ' +
      '<http://www.example.com/admin/products>; rel="http://www.example.com/described_routes#admin_products"; type="http://www.example.com/described_routes#admin_products", ' +
      '<http://www.example.com/described_routes>; rel="http://www.example.com/described_routes#described_routes"; type="http://www.example.com/described_routes#described_routes", ' +
      '<http://www.example.com/pages>; rel="http://www.example.com/described_routes#pages"; type="http://www.example.com/described_routes#pages", ' +
      '<http://www.example.com/users>; rel="http://www.example.com/described_routes#users"; type="http://www.example.com/described_routes#users"',
      headers["Link"])
  end

  def test_users_headers
    get "/users"
    assert_equal(
      '<http://www.example.com/users>; rel="self"; type="http://www.example.com/described_routes#users", ' +
      '<http://www.example.com/described_routes/users>; rel="describedby"; type="http://www.example.com/described_routes#ResourceTemplate", ' +
      '<http://www.example.com/>; rel="up"; type="http://www.example.com/described_routes#root", ' +
      '<http://www.example.com/users/new>; rel="http://www.example.com/described_routes/users#new_user"; type="http://www.example.com/described_routes#new_user"',
      headers["Link"])
  end

  def test_user_headers
    get "/users/dojo"
    assert_equal(
      '<http://www.example.com/users/dojo>; rel="self"; type="http://www.example.com/described_routes#user", ' +
      '<http://www.example.com/described_routes/user>; rel="describedby"; type="http://www.example.com/described_routes#ResourceTemplate", ' +
      '<http://www.example.com/described_routes/user?user_id=dojo>; rel="describedby"; type="http://www.example.com/described_routes#ResourceTemplate", ' +
      '<http://www.example.com/users>; rel="up"; type="http://www.example.com/described_routes#users", ' +
      '<http://www.example.com/users/dojo/edit>; rel="edit"; rel="http://www.example.com/described_routes/user#edit"; type="http://www.example.com/described_routes#edit_user", ' +
      '<http://www.example.com/users/dojo/articles>; rel="http://www.example.com/described_routes/user#articles"; type="http://www.example.com/described_routes#user_articles", ' +
      '<http://www.example.com/users/dojo/profile>; rel="http://www.example.com/described_routes/user#profile"; type="http://www.example.com/described_routes#user_profile"',
      headers["Link"])
  end
end
