require 'twada-savannah'
require 'json-schema'

module TWadaSavannah
  #
  # Payload of IssueCommentEvent from coveralls
  #
  # @see https://developer.github.com/v3/activity/events/types/#issuecommentevent
  # @see https://github.com/coveralls
  #
  class Payload
    def initialize(payload)
      @payload = payload
    end

    def id
      "#{repository}/#{comment_id}"
    end

    def action
      @payload['action']
    end

    def comment_body
      @payload['comment']['body']
    end

    def comment_id
      @payload['comment']['id']
    end

    def comment_user_id
      @payload['comment']['user']['id']
    end

    def issue_number
      @payload['issue']['number']
    end

    def repository
      @payload['repository']['full_name']
    end

    def valid?
      valid_schema? && valid_data?
    end

    def commented_by?(user_id)
      comment_user_id.to_s == user_id.to_s
    end

    private

    def valid_schema?
      schema_file = File.dirname(__FILE__) + '/payload_schema.json'
      JSON::Validator.validate(schema_file, @payload)
    end

    def valid_data?
      action == 'created'
    end
  end
end
