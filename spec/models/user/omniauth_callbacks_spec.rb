# coding: utf-8
require "spec_helper"

describe User::OmniauthCallbacks do
  let(:callback) { Class.new.extend(User::OmniauthCallbacks) }
  let(:data) { { "email" => "email@example.com", "nickname" => "_why" } }
  let(:uid) { "42" }

  describe "new_from_provider_data" do
    it "should respond to :new_from_provider_data" do
      callback.should respond_to(:new_from_provider_data)
    end

    it "should create a new user" do
      callback.new_from_provider_data(nil, nil, data).should be_a(User)
    end

    it "should handle provider weibo properly" do
      callback.new_from_provider_data("weibo", uid, data.merge!({'email' => nil})).email.should == "weibo+42@example.com"
    end

    it "should handle provider douban properly" do
      callback.new_from_provider_data("douban", uid, data.merge!({'email' => nil})).email.should == "douban+42@example.com"
    end

    it "should escape illegal characters in nicknames properly" do
      data["nickname"] = "I <3 Rails中文"
      callback.new_from_provider_data(nil, nil, data).login.should == "I__3_Rails中文"
    end

    it "should generate random login if login is empty" do
      data["nickname"] = ""
      time = Time.now
      Time.stub(:now).and_return(time)
      callback.new_from_provider_data(nil, nil, data).login.should == "u#{time.to_i}"
    end

    it "should generate random login if login is duplicated" do
      callback.new_from_provider_data(nil, nil, data).save # create a new user first
      time = Time.now
      Time.stub(:now).and_return(time)
      callback.new_from_provider_data(nil, nil, data).login.should == "u#{time.to_i}"
    end

    it "should generate some random password" do
      callback.new_from_provider_data(nil, nil, data).password.should_not be_blank
    end

    it "should set user location" do
      data["location"] = "Shanghai"
      callback.new_from_provider_data(nil, nil, data).location.should == "Shanghai"
    end

    it "should set user tagline" do
      description = data["description"] = "A newbie Ruby developer"
      callback.new_from_provider_data(nil, nil, data).tagline.should == description
    end

    it "should convert weibo image url" do
      data["image"] = "http://tp3.sinaimg.cn/1689213974/50/1266825599/1"
      url = callback.send(:convert_image_url, 'weibo', data['image'])
      url.should == 'http://tp3.sinaimg.cn/1689213974/180/1266825599/1.jpg'
    end

    it "should convert douban image url" do
      data["image"] = "http://img3.douban.com/icon/u36865564-2.jpg"
      url = callback.send(:convert_image_url, 'douban', data['image'])
      url.should == 'http://img3.douban.com/icon/ul36865564-2.jpg'
    end

    it "should setup weibo avatar from image url" do
      data["image"] = "http://tp3.sinaimg.cn/1689213974/50/1266825599/1"
      callback.new_from_provider_data('weibo', uid, data).avatar.should be_present
    end

    it "should setup douban avatar from image url" do
      data["image"] = "http://img3.douban.com/icon/u36865564-2.jpg"
      callback.new_from_provider_data('douban', uid, data).avatar.should be_present
    end
  end
end
