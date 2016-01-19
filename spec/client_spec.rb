require 'spec_helper'
require 'webmock'
require 'webmock/rspec'
WebMock.disable_net_connect!

module DelSolr

  describe Client do

    let(:server) { "localhost" }
    let(:port) { 8983 }
    let(:path) { "/solr" }
    let(:base_url) { "http://#{server}:#{port}#{path}" }

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

    it "indicates success on successful commit for solr 3.4" do
      c = setup_client
      expect(c.connection).to receive(:post) { build_http_response(SOLR_34_SUCCESS) }
      expect(c.commit!).to be_truthy
    end

    it "indicates success on successful commit" do
      c = setup_client
      expect(c.connection).to receive(:post) { build_http_response(SUCCESS) }
      expect(c.commit!).to be_truthy
    end

    it "sends the correct update request" do
      c = setup_client

      doc = DelSolr::Document.new
      doc.add_field(:id, 123)
      doc.add_field(:name, 'mp3 player')

      expected_post_data = "<add>\n#{doc.xml}\n</add>\n"

      expect(c.update(doc)).to be_truthy
      expect(c.pending_documents.length).to eq(1)

      stub_request(:post, "#{base_url}/update").
        with(:body => expected_post_data, :headers => CONTENT_TYPE).
        to_return(:body => SUCCESS)

      expect(c.post_update!).to be_truthy
      expect(c.pending_documents.length).to eq(0)
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
