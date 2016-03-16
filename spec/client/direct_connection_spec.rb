require 'spec_helper'
require 'delsolr/client/direct_connection'

module DelSolr

  describe Client::DirectConnection do
    let(:conn) {
      described_class.new(:server => "localhost", :port => 1234)
    }

    it "should use the default faraday adapter" do
      expect(conn.faraday.class).to eq(Faraday::Connection)
    end

    it 'gets the collection from opts' do
      expect(conn.collection(:collection => 'test1')).to eq('test1')
    end
  end

end
