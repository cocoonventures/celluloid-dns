#!/usr/bin/env ruby

# Copyright, 2012, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'celluloid/dns'
require 'celluloid/dns/extensions/string'

module Celluloid::DNS::TruncationSpec
	SERVER_PORTS = [[:udp, '127.0.0.1', 5520], [:tcp, '127.0.0.1', 5520]]
	IN = Resolv::DNS::Resource::IN
	
	class TestServer < Celluloid::DNS::Server
		def process(name, resource_class, transaction)
			case [name, resource_class]
			when ["truncation", IN::TXT]
				text = "Hello World! " * 100
				transaction.respond!(*text.chunked)
			else
				transaction.fail!(:NXDomain)
			end
		end
	end
	
	describe "Celluloid::DNS Truncation Server" do
		before(:all) do
			@test_server = TestServer.new(listen: SERVER_PORTS)
			@test_server.run
		end
		
		after(:all) do
			@test_server.terminate
		end

		it "should use tcp because of large response" do
			resolver = Celluloid::DNS::Resolver.new(SERVER_PORTS)
	
			response = resolver.query("truncation", IN::TXT)
	
			text = response.answer.first
	
			expect(text[2].strings.join).to be == ("Hello World! " * 100)
		end
	end
end
