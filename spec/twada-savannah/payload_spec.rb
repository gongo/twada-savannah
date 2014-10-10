require 'spec_helper'
require 'twada-savannah/payload'

describe TWadaSavannah::Payload do
  let(:payload) { described_class.new(JSON.parse(payload_json)) }

  describe 'valid json' do
    let(:payload_json) do
      File.read(File.dirname(__FILE__) + '/payload_json/payload.json')
    end

    it { expect(payload).to be_valid }

    it 'should return payload parameters' do
      expect(payload.id).to eq 'user/repo/777'
      expect(payload.action).to eq 'created'
      expect(payload.comment_body).to match(/Coverage decreased/)
      expect(payload.comment_user_id).to eq 2354108
      expect(payload.issue_number).to eq 666
      expect(payload.comment_id).to eq 777
      expect(payload.repository).to eq 'user/repo'
    end
  end

  describe 'invalid json' do
    let(:payload_json) do
      '{ "action": "created" }'
    end

    it { expect(payload).not_to be_valid }
  end
end
