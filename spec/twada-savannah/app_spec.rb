require 'spec_helper'
require 'twada-savannah/app'
require 'rack/test'
require 'rspec/request_describer'
require 'memcache_mock'

describe TWadaSavannah::App do
  include Rack::Test::Methods
  include RSpec::RequestDescriber

  def app
    described_class
  end

  before(:all) do
    app.settings.cache = MemcacheMock.new
  end

  before(:each) do
    app.settings.cache.flush_all
  end

  it 'say "omae ieruno?"' do
    get '/twada.png' do
      expect(last_response).to be_ok
      expect(last_response.headers['Content-Type']).to eq 'image/png'
    end
  end

  describe 'GET /' do
    it { should be_ok }
    it { should match '<title>twada-savannah</title>' }
  end

  describe 'POST /' do
    before do
      env['HTTP_X_GITHUB_EVENT'] = 'issue_comment'
    end

    let(:request_body) do
      File.read(File.dirname(__FILE__) + '/payload_json/payload.json')
    end

    let(:client) do
      user    = double(id: app::TARGET_COMMENTER)
      comment = double(user: user, created_at: Time.now - 5) # 5 sec ago
      double(comment: comment)
    end

    context 'valid webhook' do
      before do
        expect(client).to receive(:add_comment)
        allow_any_instance_of(app).to receive(:github_client).and_return(client)
      end

      it { should be_ok }
    end

    context 'Without X_GITHUB_EVENT environment' do
      before { env.delete('HTTP_X_GITHUB_EVENT') }

      it { should be_bad_request }
      it { expect(subject.body).to eq 'event' }
    end

    context 'With invalid X_GITHUB_EVENT environment' do
      before { env['HTTP_X_GITHUB_EVENT'] = 'invalid' }

      it { should be_bad_request }
      it { expect(subject.body).to eq 'event' }
    end

    context 'With invalid request body' do
      let(:request_body) { '{}' }

      it { should be_bad_request }
      it { expect(subject.body).to eq 'request' }
    end

    context 'commenter is not coderwalls' do
      let(:request_body) do
        File.read(File.dirname(__FILE__) + '/payload_json/other_user_payload.json')
      end

      it { should be_bad_request }
      it { expect(subject.body).to eq 'commenter' }
    end

    context 'cached payload.id' do
      before do
        # user/repo/comment_id at payload_json/payload.json
        app.settings.cache.set('user/repo/777', '1')
      end

      it { should be_bad_request }
      it { expect(subject.body).to eq 'already' }
    end

    context 'specified comment that not exists' do
      before do
        client = double(comment: nil)
        allow_any_instance_of(app).to receive(:github_client).and_return(client)
      end

      it { should be_bad_request }
      it { expect(subject.body).to eq 'comment id' }
    end

    context 'specified comment that was not created at within 10 sec' do
      let(:client) do
        comment = double(created_at: Time.now - 11) # 11 sec ago
        double(comment: comment)
      end

      before do
        allow_any_instance_of(app).to receive(:github_client).and_return(client)
      end

      it { should be_bad_request }
      it { expect(subject.body).to eq 'comment time' }
    end

    context 'User who made specified comment is different' do
      let(:client) do
        user    = double(id: 12345)
        comment = double(created_at: Time.now - 5, user: user)
        double(comment: comment)
      end

      before do
        allow_any_instance_of(app).to receive(:github_client).and_return(client)
      end

      it { should be_bad_request }
      it { expect(subject.body).to eq 'comment user' }
    end

    context 'current comment was inform coverage increased' do
      let(:request_body) do
        File.read(File.dirname(__FILE__) + '/payload_json/increased_payload.json')
      end

      before do
        allow_any_instance_of(app).to receive(:github_client).and_return(client)
      end

      it { expect(subject.status).to eq 204 }
    end
  end
end
