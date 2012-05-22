# coding: utf-8

FactoryGirl.define do
  factory :user do
    sequence(:name){ |n| "中文發Ac2_#{n}" }
    sequence(:login){ |n| "中文發Bd12_#{n}" }
    sequence(:email){ |n| "email#{n}@ruby-chine.org" }
    password 'password'
    password_confirmation 'password'
    location "China"
  end

  factory :admin, :parent => :user do
    email Setting.admin_emails.first
  end

  factory :wiki_editor, :parent => :user

  factory :non_wiki_editor, :parent => :user do
    verified false
  end
end
