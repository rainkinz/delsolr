require 'spec_helper'
require 'webmock'
require 'webmock/rspec'
WebMock.disable_net_connect!

module DelSolr

  describe Client do

    let(:server) { "localhost" }
    let(:port) { 8983 }
    let(:path) { "/solr" }

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

    it "queries" do
      c = setup_client(:path => '/abcsolr')

      stub_request(:post, "#{base_url('/abcsolr')}/select").
        with(:body => "q=123&wt=json&qt=standard&rows=10&start=0&fl=id%2Cunique_id%2Cscore").
        to_return(:body => RESPONSE_BUFFER)

      r = c.query('standard', :query => '123')
      expect(r).to_not be_nil
      expect(r.ids.sort).to eq([1,3,4,5,7,8,9,10,11,12])
      expect(r.from_cache?).to be_falsy
    end

    def setup_client(options = {})
      DelSolr::Client.new({:server => 'localhost', :port => 8983, :path => "/solr"}.merge(options))
    end

    def build_http_response(body)
      response = Net::HTTPOK.new('1.1', '200', 'OK')
      expect(response).to receive(:body) { body }
      response
    end

    def base_url(path = "/solr")
      "http://#{server}:#{port}#{path}"
    end


  INVALID_BUFFER = %{
    <html>
    <body>
    Solr returns errors as html
    </body>
    </html>
  }

  RESPONSE_BUFFER = {
     'responseHeader'=>{
      'status'=>0,
      'QTime'=>151,
      'params'=>{
            'wt'=>'ruby',
            'rows'=>'10',
            'explainOther'=>'',
            'start'=>'0',
            'hl.fl'=>'',
            'indent'=>'on',
            'hl'=>'on',
            'q'=>'index_type:widget',
            'fl'=>'*,score',
            'qt'=>'standard',
            'version'=>'2.2'}},
     'response'=>{'numFound'=>1522698,'start'=>0,'maxScore'=>1.5583541,'docs'=>[
            {
             'index_type'=>'widget',
             'id'=>1,
             'unique_id'=>'1_widget',
             'score'=>1.5583541},
            {
             'index_type'=>'widget',
             'id'=>3,
             'unique_id'=>'3_widget',
             'score'=>1.5583541},
            {
             'index_type'=>'widget',
             'id'=>4,
             'unique_id'=>'4_widget',
             'score'=>1.5583541},
            {
             'index_type'=>'widget',
             'id'=>5,
             'unique_id'=>'5_widget',
             'score'=>1.5583541},
            {
             'index_type'=>'widget',
             'id'=>7,
             'unique_id'=>'7_widget',
             'score'=>1.5583541},
            {
             'index_type'=>'widget',
             'id'=>8,
             'unique_id'=>'8_widget',
             'score'=>1.5583541},
            {
             'index_type'=>'widget',
             'id'=>9,
             'unique_id'=>'9_widget',
             'score'=>1.5583541},
            {
             'index_type'=>'widget',
             'id'=>10,
             'unique_id'=>'10_widget',
             'score'=>1.5583541},
            {
             'index_type'=>'widget',
             'id'=>11,
             'unique_id'=>'11_widget',
             'score'=>1.5583541},
            {
             'index_type'=>'widget',
             'id'=>12,
             'unique_id'=>'12_widget',
             'score'=>1.5583541}]
     },
     'facet_counts'=>{
      'facet_queries'=>{
        'city_idm:19596' => 392},
      'facet_fields'=>{
        'available_b'=>[
          'false',1328],
        'onsale_b'=>[
          'false',1182,
          'true',174]}},
     'highlighting'=>{
      '1_widget'=>{},
      '3_widget'=>{},
      '4_widget'=>{},
      '5_widget'=>{},
      '7_widget'=>{},
      '8_widget'=>{},
      '9_widget'=>{},
      '10_widget'=>{},
      '11_widget'=>{},
      '12_widget'=>{}}
  }.to_json

  end
end
