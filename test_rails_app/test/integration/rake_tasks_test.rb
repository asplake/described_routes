require 'test/unit'
require 'test/test_helper'
require 'described_routes/rake_task_methods'

class RakeTasksTest < Test::Unit::TestCase
  def setup
    DescribedRoutes::RailsRoutes.parsed_hook = nil
  end
  
  def teardown
    DescribedRoutes::RailsRoutes.parsed_hook = nil
  end
  
  def read_fixture(extension)
    File.read(File.dirname(__FILE__) + '/../fixtures/build_time/described_routes.' + extension)
  end
  
  def test_text
    assert_equal(read_fixture("text"), DescribedRoutes::RakeTaskMethods.text)
  end

  def test_json
    assert_equal(read_fixture("json").chomp, DescribedRoutes::RakeTaskMethods.json)
  end

  def test_yaml
    assert_equal(read_fixture("yaml"), DescribedRoutes::RakeTaskMethods.yaml)
  end

  def test_xml
    assert_equal(read_fixture("xml"), DescribedRoutes::RakeTaskMethods.xml)
  end
end
