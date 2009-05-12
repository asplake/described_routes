require 'test/unit'
require 'described_routes/resource_template'

class TestResourceTemplate < Test::Unit::TestCase
  attr_reader :json, :resource_templates, :resource_templates_by_name, :user_articles, :user_article, :edit_user_article
  
  def setup
    @json ||= File.read(File.dirname(__FILE__) + "/fixtures/described_routes_test.json")
    @resource_templates = DescribedRoutes::ResourceTemplate.parse_json(json)
    @resource_templates_by_name = DescribedRoutes::ResourceTemplate.all_by_name(@resource_templates)
    @user_articles = @resource_templates_by_name["user_articles"]
    @user_article = @resource_templates_by_name["user_article"]
    @edit_user_article = @resource_templates_by_name["edit_user_article"]
  end

  def test_fixture
    assert_kind_of(DescribedRoutes::ResourceTemplate, user_articles)
    assert_kind_of(DescribedRoutes::ResourceTemplate, user_article)
    assert_kind_of(DescribedRoutes::ResourceTemplate, edit_user_article)

    assert_equal("user_article", user_article.name)
    assert_equal(["user_id", "article_id"], user_article.params)
    assert_equal(["format"], user_article.optional_params)

    assert_equal("articles", user_articles.rel)
    assert_nil(user_article.rel)
    assert_equal("edit", edit_user_article.rel)
    
    assert_equal("/users/{user_id}/articles{-prefix|.|format}", user_articles.path_template)
    assert_equal("http://localhost:3000/users/{user_id}/articles{-prefix|.|format}", user_articles.uri_template)

    assert(user_articles.resource_templates.member?(user_article))
    assert(user_article.resource_templates.member?(edit_user_article))
  end
  
  def test_json
    assert_equal(
        JSON.parse(json),
        JSON.parse(DescribedRoutes::ResourceTemplate.to_json(resource_templates)))
  end
  
  def test_yaml
    assert_equal(
        JSON.parse(json),
        YAML.load(DescribedRoutes::ResourceTemplate.to_yaml(resource_templates)))
  end
  
  def test_positional_params
    assert_equal(["user_id", "article_id", "format"], user_article.positional_params(nil))
    assert_equal(["article_id", "format"], user_article.positional_params(user_articles))
  end
end
