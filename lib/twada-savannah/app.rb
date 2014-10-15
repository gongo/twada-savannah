require 'twada-savannah'
require 'sinatra/base'
require 'sinatra/contrib'
require 'sinatra/reloader'
require 'dalli'
require 'time'
require 'slim'

module TWadaSavannah
  class App < Sinatra::Base
    TARGET_COMMENTER = '2354108' # https://github.com/coveralls

    configure do
      cache = Dalli::Client.new(
        ENV['MEMCACHEDCLOUD_SERVERS'],
        username: ENV['MEMCACHEDCLOUD_USERNAME'],
        password: ENV['MEMCACHEDCLOUD_PASSWORD'],
        expires_in: 3600 * 24 # 1 day
      )
      set :cache, cache
      set :views, File.dirname(__FILE__) + '/../../views'
      set :public_folder, File.dirname(__FILE__) + '/../../public'
    end

    configure :development do
      register Sinatra::Reloader
    end

    get '/' do
      slim :index
    end

    post '/' do
      if (errmsg = validate_request)
        bad_request errmsg
      end

      settings.cache.set(payload.id, '1')
      no_content 'Coverage not decreased' unless coverage_decreased?

      github_client.add_comment(omae_ieruno_message)
    end

    get '/twada.png' do
      send_file 'public/twada_savanna_lion.png', type: :png
    end

    private

    def no_content(body = nil)
      halt 204, body
    end

    def bad_request(body = nil)
      error 400, body
    end

    def validate_request
      return 'event' unless issue_comment_event?

      return 'request'   unless payload.valid?
      return 'commenter' unless payload.commented_by?(TARGET_COMMENTER)
      return 'already'   if settings.cache.get(payload.id)

      comment = github_client.comment(payload.comment_id)

      return 'comment id'   unless comment
      return 'comment time' unless valid_within_comment_created_at?(comment)

      nil
    end

    def issue_comment_event?
      request.env['HTTP_X_GITHUB_EVENT'] == 'issue_comment'
    end

    def coverage_decreased?
      !payload.comment_body.match(/Coverage decreased .* when pulling/).nil?
    end

    #
    # Return true if comment was created at within **10** sec
    #
    # @param  Sawyer::Resource  comment
    #
    def valid_within_comment_created_at?(comment)
      now = Time.now
      (now - 10) <= comment.created_at && comment.created_at <= now
    end

    def payload
      @payload ||= Payload.new(JSON.parse(request.body.read))
    end

    def github_client
      @github_client ||= GitHub.new(payload.repository, payload.issue_number)
    end

    def omae_ieruno_message
      <<-EOS
> Coverage decreased

![twada](http://#{request.host}/twada.png)
      EOS
    end
  end
end
