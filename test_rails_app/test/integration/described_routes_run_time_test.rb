require 'test/test_helper'

class DescribedRoutesRunTimeTest < ActionController::IntegrationTest
  def read_fixture(extension)
    File.read(File.dirname(__FILE__) + '/../fixtures/run_time/described_routes.' + extension)
  end
  
  def test_text
    get "/described_routes.text"
    assert_response :success
    assert_equal(read_fixture("text"), body)
  end

  def test_json
    get "/described_routes.json"
    assert_response :success
    assert_equal(read_fixture("json").chomp, body)
  end

  def test_xml
    get "/described_routes.xml"
    assert_response :success
    assert_equal(read_fixture("xml"), body)
  end

  def test_yaml
    get "/described_routes.yaml"
    assert_response :success
    assert_equal(read_fixture("yaml"), body)
  end

  def test_partial_expand
    get "/described_routes/new_user_profile.text?user_id=dojo&format=json"
    assert_equal("new_user_profile new_user_profile GET http://www.example.com/users/dojo/profile/new.json", body.chomp)
  end
end
