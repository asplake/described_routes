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

  def test_yaml_short
    get "/described_routes.yaml?short=1"
    assert_response :success
    assert_equal(read_fixture("yaml_short"), body)
  end
end
