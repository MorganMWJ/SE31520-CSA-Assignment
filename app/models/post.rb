class Post < ApplicationRecord
  belongs_to :user

  has_many :replies, class_name: "Post", foreign_key: "thread_id"
  belongs_to :thread, class_name: "Post", optional: true
end
