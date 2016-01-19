require 'spec_helper'

module DelSolr

  describe Client do

    SUCCESS = '<result status="0"></result>'
    SOLR_34_SUCCESS = %Q{<?xml version="1.0" encoding="UTF-8"?>
<response>
<lst name="responseHeader"><int name="status">0</int><int name="QTime">4</int></lst>
</response>}
    FAILURE = '<result status="1"></result>'
    CONTENT_TYPE = {'Content-type' => 'text/xml;charset=utf-8'}

    it "is created without exception" do
      s = DelSolr::Client.new(:server => 'localhost', :port => 8983)
      expect(s).to_not be_nil
    end

    it "indicates success on successful commit" do
      c = setup_client
      expect(c.connection).to receive(:post) { build_http_response(SOLR_34_SUCCESS) }
      expect(c.commit!).to be_truthy
    end


    def setup_client(options = {})
      DelSolr::Client.new({:server => 'localhost', :port => 8983}.merge(options))
    end

    def build_http_response(body)
      response = Net::HTTPOK.new('1.1', '200', 'OK')
      expect(response).to receive(:body) { body }
      response
    end

  end
end
