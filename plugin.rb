# name: custom-fields-query
# about: query user by custom field name and value
# version: 0.1
# authors: Hackafe

after_initialize do
  module ::CustomFieldsQueryPlugin
    class Engine < ::Rails::Engine
      engine_name "custom_fields_query_plugin"
      isolate_namespace CustomFieldsQueryPlugin
    end

    class QueryUserController < ActionController::Base
      before_filter :ensure_api_key
      before_filter :ensure_query_params

      def queryUser
        field_index = request['field_index']
        field_value = ActiveRecord::Base.connection.quote(request['field_value'])
        field_name = ActiveRecord::Base.connection.quote("user_field_#{field_index}")
        sql = <<-SQL
          SELECT
              users.username, users.email
              FROM user_custom_fields, users
              WHERE value=#{field_value}
              and users.id != -1
        SQL

        result = ActiveRecord::Base.
          connection.
          execute(sql)
        render json: result
      end


      def api_key_valid
        request["api_key"] && ApiKey.where(key: request["api_key"]).exists?
      end

      private

      def render_forbidden
        render status: :forbidden, json: false
      end

      def ensure_api_key
        render_forbidden unless api_key_valid
      end

      def render_missing_params
        render status: :bad_request, json: {error: 'field_index or field_value param missing'}
      end

      def ensure_query_params
        render_missing_params if request['field_value'].blank?
      end
    end
  end

  CustomFieldsQueryPlugin::Engine.routes.draw do
    get '/' => 'query_user#queryUser'
  end

  Discourse::Application.routes.append do
    mount CustomFieldsQueryPlugin::Engine, at: '/query_user'
  end

end
