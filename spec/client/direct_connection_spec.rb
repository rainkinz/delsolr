require 'spec_helper'
require 'delsolr/client/direct_connection'

module DelSolr

  describe Client::DirectConnection do

    it "should use the default faraday adapter" do
      conn = described_class.new(:server => "localhost", :port => 1234)
      expect(conn.faraday.class).to eq(Faraday::Connection)
    end
  end

end
