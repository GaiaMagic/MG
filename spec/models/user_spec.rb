# coding: utf-8
require 'spec_helper'

describe User do
  let(:topic) { Factory :topic }
  let(:user)  { Factory :user }
  let(:user2)  { Factory :user }
  let(:reply) { Factory :reply }
  let(:user_for_delete1) { Factory :user }
  let(:user_for_delete2) { Factory :user }

  describe '#read_topic?' do
    before do
      Rails.cache.write("user:#{user.id}:topic_read:#{topic.id}", nil)
    end

    it 'marks the topic as unread' do
      user.topic_read?(topic).should == false
      user.read_topic(topic)
      user.topic_read?(topic).should == true
      user2.topic_read?(topic).should == false
    end

    it "marks the topic as unread when got new reply" do
      topic.replies << reply
      user.topic_read?(topic).should == false
      user.read_topic(topic)
      user.topic_read?(topic).should == true
    end

    it "user can soft_delete" do
      user_for_delete1.soft_delete
      user_for_delete1.reload
      user_for_delete1.login.should == "Guest"
      user_for_delete1.state.should == -1
      user_for_delete2.soft_delete
      user_for_delete1.reload
      user_for_delete1.login.should == "Guest"
      user_for_delete1.state.should == -1
      user_for_delete1.authorizations.should == []
    end
  end

  describe "location" do
    it "should not get results when user location not set" do
      Location.count == 0
    end

    it "should get results when user location is set" do
      user.location = "hangzhou"
      user2.location = "Hongkong"
      Location.count == 2
    end

    it "should update users_count when user location changed" do
      old_name = user.location
      new_name = "HongKong"
      old_location = Location.find_by_name(old_name)
      hk_location = Factory(:location, :name => new_name, :users_count => 20)
      user.location = new_name
      user.save
      user.reload
      user.location.should == new_name
      user.location_id.should == hk_location.id
      Location.find_by_name(old_name).users_count.should == (old_location.users_count - 1)
      Location.find_by_name(new_name).users_count.should == (hk_location.users_count + 1)
    end
  end

  describe "admin?" do
    let (:admin) { Factory :admin }
    it "should know you are an admin" do
      admin.should be_admin
    end

    it "should know normal user is not admin" do
      user.should_not be_admin
    end
  end

  describe "wiki_editor?" do
    let (:admin) { Factory :admin }
    it "should know admin is wiki editor" do
      admin.should be_wiki_editor
    end

    it "should know verified user is wiki editor" do
      user.verified = true
      user.should be_wiki_editor
    end

    it "should know not verified user is not a wiki editor" do
      user.verified = false
      user.should_not be_wiki_editor
    end
  end

  describe "roles" do
    subject { user }

    context "when is a new user" do
      let(:user) { Factory :user }
      it { should have_role(:member) }
    end

    context "when is admin" do
      let(:user) { Factory :admin }
      it { should have_role(:admin) }
    end

    context "when is wiki editor" do
      let(:user) { Factory :wiki_editor }
      it { should have_role(:wiki_editor) }
    end

    context "when ask for some random role" do
      let(:user) { Factory :user }
      it { should_not have_role(:savior_of_the_broken) }
    end
  end

  describe "private token generate" do
    it "should generate new token" do
      old_token = user.private_token
      user.update_private_token
      user.private_token.should_not == old_token
      user.update_private_token
      user.private_token.should_not == old_token
    end
  end

  describe "favorite topic" do
    it "should favorite a topic" do
      user.favorite_topic(topic.id)
      user.favorite_topic_ids.include?(topic.id).should == true

      user.favorite_topic(nil).should == false
      user.favorite_topic(topic.id.to_s).should == false
      user.favorite_topic_ids.include?(topic.id).should == true
    end

    it "should unfavorite a topic" do
      user.unfavorite_topic(topic.id)
      user.favorite_topic_ids.include?(topic.id).should == false
      user.unfavorite_topic(nil).should == false
      user.unfavorite_topic(topic.id.to_s).should == true
    end
  end

  describe 'login field' do
    it "should validate format" do
      user.login = '中文ABcd12_'
      user.should be_valid
      user.login = '中 文ABcd12_'
      user.should_not be_valid
      user.login = '*中文ABcd12_'
      user.should_not be_valid
    end
  end

  describe 'bind sns' do
    let(:respond) do
      {
        "uid" => "123",
        "provider" => "weibo",
        "credentials" => { 'token' => 'token', 'secret' => 'secret' }
      }
    end

    it "should bind sns accout" do
      user.bind_service(respond)
      user.bind?(:weibo).should be_true
      user.bind?('weibo').should be_true
    end
  end
end
