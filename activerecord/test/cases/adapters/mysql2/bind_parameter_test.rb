# frozen_string_literal: true

require "cases/helper"
require "models/topic"
require "models/post"

module ActiveRecord
  module ConnectionAdapters
    class Mysql2Adapter
      class BindParameterTest < ActiveRecord::Mysql2TestCase
        fixtures :topics, :posts

        def test_update_question_marks
          str       = "foo?bar"
          x         = Topic.first
          x.title   = str
          x.content = str
          x.save!
          x.reload
          assert_equal str, x.title
          assert_equal str, x.content
        end

        def test_create_question_marks
          str = "foo?bar"
          x   = Topic.create!(title: str, content: str)
          x.reload
          assert_equal str, x.title
          assert_equal str, x.content
        end

        def test_update_null_bytes
          str       = "foo\0bar"
          x         = Topic.first
          x.title   = str
          x.content = str
          x.save!
          x.reload
          assert_equal str, x.title
          assert_equal str, x.content
        end

        def test_create_null_bytes
          str = "foo\0bar"
          x   = Topic.create!(title: str, content: str)
          x.reload
          assert_equal str, x.title
          assert_equal str, x.content
        end

        def test_where_with_string_for_string_column_using_bind_parameters
          count = Post.where("title = ?", "Welcome to the weblog").count
          assert_equal 1, count
        end

        def test_where_with_integer_for_string_column_using_bind_parameters
          count = Post.where("title = ?", 0).count
          assert_equal 0, count
        end

        def test_where_with_float_for_string_column_using_bind_parameters
          count = Post.where("title = ?", 0.0).count
          assert_equal 0, count
        end

        def test_where_with_boolean_for_string_column_using_bind_parameters
          count = Post.where("title = ?", false).count
          assert_equal 0, count
        end

        def test_where_with_decimal_for_string_column_using_bind_parameters
          count = Post.where("title = ?", BigDecimal(0)).count
          assert_equal 0, count
        end

        def test_where_with_duration_for_string_column_using_bind_parameters
          count = Post.where("title = ?", 0.seconds).count
          assert_equal 0, count
        end
      end
    end
  end
end
