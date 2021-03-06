require 'test/unit'
require 'resource_template'

class TestResourceTemplate < Test::Unit::TestCase
  attr_reader :json, :resource_templates, :resource_templates_by_name, :user, :user_articles, :user_article, :edit_user_article
  
  def setup
    @json ||= File.read(File.dirname(__FILE__) + '/fixtures/described_routes_test.json')
    @resource_templates = ResourceTemplate::ResourceTemplates.new(JSON.parse(@json))
    @resource_templates_by_name = @resource_templates.all_by_name
    @user = @resource_templates_by_name['user']
    @user_articles = @resource_templates_by_name['user_articles']
    @user_article = @resource_templates_by_name['user_article']
    @edit_user_article = @resource_templates_by_name['edit_user_article']
  end

  def test_fixture
    assert_kind_of(ResourceTemplate, user_articles)
    assert_kind_of(ResourceTemplate, user_article)
    assert_kind_of(ResourceTemplate, edit_user_article)

    assert_equal('user_article', user_article.name)
    assert_equal(['user_id', 'article_id'], user_article.params)
    assert_equal(['format'], user_article.optional_params)

    assert_equal('articles', user_articles.rel)
    assert_nil(user_article.rel)
    assert_equal('edit', edit_user_article.rel)
    
    assert_equal('/users/{user_id}/articles{-prefix|.|format}', user_articles.path_template)
    assert_equal('http://localhost:3000/users/{user_id}/articles{-prefix|.|format}', user_articles.uri_template)

    assert(user_articles.resource_templates.member?(user_article))
    assert(user_article.resource_templates.member?(edit_user_article))
  end
  
  def test_json
    assert_equal(
        JSON.parse(json),
        JSON.parse(resource_templates.to_json))
  end
  
  def test_yaml
    assert_equal(
        JSON.parse(json),
        YAML.load(resource_templates.to_yaml))
  end
  
  def test_find_by_rel
    assert_equal([user_article], user_articles.find_by_rel(nil))
    assert_equal([edit_user_article], user_article.find_by_rel('edit'))
  end
  
  def test_positional_params
    assert_equal(['user_id', 'article_id', 'format'], user_article.positional_params(nil))
    assert_equal(['article_id', 'format'], user_article.positional_params(user_articles))
  end
  
  def test_partial_expand
    expanded_user_articles = user_articles.partial_expand('user_id' => 'dojo', 'format' => 'json')
    expanded_edit_user_article = expanded_user_articles.resource_templates.all_by_name['edit_user_article']
    
    assert_equal(['article_id'], expanded_edit_user_article.params)
    assert(expanded_edit_user_article.optional_params.empty?)
    assert_equal('/users/dojo/articles/{article_id}/edit.json', expanded_edit_user_article.path_template)
  end  
  
  def test_uri_for
    assert_equal('http://localhost:3000/users/dojo/articles', user_articles.uri_for('user_id' => 'dojo'))
    assert_equal('http://localhost:3000/users/dojo/articles.json', user_articles.uri_for('user_id' => 'dojo', 'format' => 'json'))
  end
  
  def test_uri_for_with_missing_params
    assert_raises(ArgumentError) do
      user_articles.uri_for('format' => 'json') # no user_id param
    end
  end
  
  def test_uri_for_with_no_uri_template
    users = ResourceTemplate.new('path_template' => '/users')
    assert_raises(RuntimeError) do
      users.uri_for({})
    end
    assert_equal('http://localhost:3000/users', users.uri_for({}, 'http://localhost:3000'))
  end

  def test_path_for
    assert_equal('/users/dojo/articles', user_articles.path_for('user_id' => 'dojo'))
    assert_equal('/users/dojo/articles.json', user_articles.path_for('user_id' => 'dojo', 'format' => 'json'))
  end
  
  def test_path_for_with_missing_params
    assert_raises(ArgumentError) do
      user_articles.path_for('format' => 'json') # no user_id param
    end
  end
  
  def test_path_for_with_no_path_template
    assert_raises(RuntimeError) do
      ResourceTemplate.new.path_for({}) # no path_template
    end
  end
  
  def test_parent
    assert_equal("user", user_articles.parent.name)
    assert_equal("users", user_articles.parent.parent.name)
    assert_nil(user_articles.parent.parent.parent)
  end
  
  def test_expand_links
    assert_equal(
      [
        {
          "name"            => "new_user_article",
          "options"         => ["GET"],
          "path_template"   => "/users/dojo/articles/new{-prefix|.|format}",
          "uri_template"    => "http://localhost:3000/users/dojo/articles/new{-prefix|.|format}",
          "rel"             => "new_user_article",
          "optional_params" => ["format"]
        },
        {
          "name"            => "recent_user_articles",
          "options"         => ["GET"],
          "path_template"   => "/users/dojo/articles/recent{-prefix|.|format}",
          "uri_template"    => "http://localhost:3000/users/dojo/articles/recent{-prefix|.|format}",
          "rel"             => "recent",
          "optional_params" => ["format"]
        }
      ],
      user_articles.resource_templates.expand_links({'user_id' => 'dojo'}).to_parsed)
  end
  
  def test_all_preorder
    assert_equal(
      [
        "user",
        "user_articles",
        "user_article",
        "edit_user_article",
        "new_user_article",
        "recent_user_articles",
        "edit_user",
        "user_profile",
        "edit_user_profile",
        "new_user_profile"
      ],
      user.all_preorder.map{|rt| rt.name})
  end
  
  def test_all_postorder
    assert_equal(
      [
        "edit_user_article",
        "user_article",
        "new_user_article",
        "recent_user_articles",
        "user_articles",
        "edit_user",
        "edit_user_profile",
        "new_user_profile",
        "user_profile",
        "user"
      ],
      user.all_postorder.map{|rt| rt.name})
  end
end
