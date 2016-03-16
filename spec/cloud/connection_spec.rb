require 'spec_helper'
require 'delsolr/cloud'

module DelSolr

  module Cloud

    describe Connection do

      let(:conn) {
        described_class.new(
          :server => 'https://mysolr.com',
          :zk_info => double("ZKInfo")
        )
      }

      it 'gets the collection from opts' do
        expect(conn.collections(:collection => 'test1')).to eq(['test1'])
        expect(conn.collections(:collections => ['test1'])).to eq(['test1'])
        expect(conn.collections(:collections => ['test1', 'test2'])).to eq(['test1', 'test2'])
        expect {
          conn.collections(:collections => nil)
        }.to raise_error(ArgumentError)
        expect {
          conn.collections(:collections => [])
        }.to raise_error(ArgumentError)
      end

    end

  end
end
