require './key_server'
require 'Delorean'

RSpec.configure do |config|
  config.include Delorean 
  #this gem is used to mocking time for checking key expiry
end

describe KeyServer, '#generate' do

  it 'should generate the correct number of keys' do
    test = KeyServer.new
    test.generate 10, 300, 30
    expect(test.keys.length).to eq(10)
  end

  it 'should generate keys which are not expired' do
    test = KeyServer.new
    test.generate 10, 300, 30
    now = Time.now.to_i
    test.keys.each do |key, val|
      expiry = val[:keep_alive_stamp] + 300
      expect(expiry).to be >= now
    end
  end

  it 'should generate keys which are not assigned' do
    test = KeyServer.new
    test.generate 10, 300, 30
    now = Time.now.to_i
    test.keys.each do |key, val|
      expect(val[:assigned_stamp]).to eq(0)
    end

    expect(test.free.length).to eq(test.keys.length)
  end

end

describe KeyServer, '#get' do

  it 'should return a key if nothing is assigned' do
    test = KeyServer.new
    test.generate 10, 300, 30
    key = test.get
    expect(key).to be_truthy
    expect(test.keys.keys).to include(key)
  end

  it 'should return a key which won\'t be available for assignment later' do
    test = KeyServer.new
    test.generate 10, 300, 30
    key = test.get
    expect(test.free.keys).not_to include(key)
    expect(test.keys[key][:assigned_stamp]).not_to eq(0)
  end

  it 'should return a key which isn\'t expired' do
    test = KeyServer.new
    test.generate 10, 300, 30
    key = test.get
    expect(test.free.keys).not_to include(key)
    now = Time.now.to_i
    expect(test.keys[key][:keep_alive_stamp] + 300).to be >= now
  end

  it 'should not return a key if all of them are assigned' do
    test = KeyServer.new
    test.generate 3, 300, 30
    3.times {
      test.get  
    }
    key = test.get
    expect(key).to be_nil
  end

  it 'should not return a key if all of them are expired' do
    test = KeyServer.new
    test.generate 3, 300, 30
    jump 301
    key = test.get
    expect(key).to be_nil
    back_to_the_present
  end

  it "should return a key if its been in use for more than 30 seconds" do
    test = KeyServer.new
    test.generate 3, 300, 30
    key = test.get
    jump 31
    test.cleanup
    expect(test.free.keys).to include(key)
    expect(test.keys[key][:assigned_stamp]).to eq(0)
    back_to_the_present
  end

end

describe KeyServer, '#refresh' do 

  it 'should refresh the key specified' do 
    test = KeyServer.new
    test.generate 3, 300, 30
    key = test.get
    jump 200
    test.refresh key
    expect(test.keys[key][:keep_alive_stamp] + 300).to be >= Time.now.to_i
    jump 200
    expect(test.keys[key][:keep_alive_stamp] + 300).to be >= Time.now.to_i
    back_to_the_present
  end

  it 'should not undelete a key which has already expired' do
    test = KeyServer.new
    test.generate 3, 300, 30
    key = test.get
    jump 400
    test.refresh key
    expect(test.keys.keys).not_to include(key)
    back_to_the_present
  end
end

describe KeyServer, '#delete' do
  
  it 'should delete a free key' do
    test = KeyServer.new
    test.generate 3, 300, 30
    key = test.keys[0]
    test.delete key
    expect(test.keys.keys).not_to include(key)
    expect(test.free.keys).not_to include(key)
  end

  it 'should delete an assigned key' do
    test = KeyServer.new
    test.generate 3, 300, 30
    key = test.get
    test.delete key
    expect(test.keys.keys).not_to include(key)
    expect(test.free.keys).not_to include(key)
  end
end

describe KeyServer, '#release' do

  it 'should release a key' do
    test = KeyServer.new
    test.generate 3, 300, 30
    key = test.get
    test.release key
    expect(test.free.keys).to include(key)
    expect(test.keys[key][:assigned_stamp]).to eq(0)
  end

end
