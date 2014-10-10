require 'twada-savannah'
require 'octokit'

module TWadaSavannah
  class GitHub
    #
    # @param  String  repository  owner/repo
    # @param  Fixnum  issue_id    github.com/#{repository}/issues/#{issue_id}
    #
    def initialize(repository, issue_id)
      @repository = repository
      @issue_id = issue_id
      @client = Octokit::Client.new access_token: ENV['GITHUB_ACCESS_TOKEN']
    end

    def add_comment(comment)
      @client.add_comment(@repository, @issue_id, comment)
    end

    def comment(comment_id)
      @client.issue_comment(@repository, comment_id)
    rescue Octokit::NotFound
      nil
    end
  end
end
