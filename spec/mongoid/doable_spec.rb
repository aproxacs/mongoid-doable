require "spec_helper"

module Doable
  class Course
  end
  class Student
  end

  class User
    include Mongoid::Document
    include Mongoid::Doable

    doer :like, :course, class_name: "Doable::Course"
    doer :like, :student, class_name: "Doable::Student", embedded: true

    doable :follow, by: "Doable::User"
    doer :follow, :user, class_name: "Doable::User"

    doer :bookmark, :course, class_name: "Doable::Course"
  end

  class Course
    include Mongoid::Document
    include Mongoid::Doable

    embeds_many :students

    doable :like, by: "Doable::User"
    doable :bookmark, by: "Doable::User"
  end

  class Student
    include Mongoid::Document
    include Mongoid::Doable

    embedded_in :course

    doable :like, by: "Doable::User"
  end
end

describe "likeable" do
  let(:user) { Doable::User.create }
  let(:course) { Doable::Course.create }

  subject { user }

  context "default values" do
    its(:liking_courses_ids) { should == [] }
    its(:liking_courses_count) { should == 0 }
    its(:liking_courses) { should == [] }
    it { subject.should_not be_liking(course) }

    context "with course" do
      subject { course }
      its(:likers_ids) { should == [] }
      its(:likers_count) { should == 0 }
      its(:likers) { should == [] }
      it { subject.should_not be_liked_by(user) }
    end
  end

  context "when a user likes course" do
    before { user.like!(course) }

    its(:liking_courses_ids) { should == [course.id] }
    its(:liking_courses_count) { should == 1 }
    its(:liking_courses) { should == [course] }
    it { subject.should be_liking(course) }

    context "with course" do
      subject { course }
      its(:likers_ids) { should == [user.id] }
      its(:likers_count) { should == 1 }
      its(:likers) { should == [user]}
      it { subject.should be_liked_by(user) }
    end

    context "when the same user likes course once more" do
      before { user.like!(course) }

      its(:liking_courses_ids) { should == [course.id] }
      its(:liking_courses_count) { should == 1 }
    end

    context "when user unlike course" do
      before { user.unlike!(course) }

      its(:liking_courses_ids) { should == [] }
      its(:liking_courses_count) { should == 0 }
      its(:liking_courses) { should == [] }
      it { subject.should_not be_liking(course) }

      context "with course" do
        subject { course }
        its(:likers_ids) { should == [] }
        its(:likers_count) { should == 0 }
        its(:likers) { should == [] }
        it { subject.should_not be_liked_by(user) }
      end

    end
  end

  context "when user unlikes course" do
    before { user.unlike!(course) }

    its(:liking_courses_ids) { should == [] }
  end


  context "for embedded document" do
    let(:student) { course.students.create }
    subject { user }

    its(:liking_students_count) { should == 0 }
    it { subject.should_not be_respond_to(:liking_students) }

    context "when a user likes student" do
      before { user.like!(student) }

      its(:liking_students_ids) { should == [student.id] }
    end
  end

end


describe "followable" do
  let(:user) { Doable::User.create }
  let(:user2) { Doable::User.create }

  subject { user }

  context "default values" do
    its(:following_users_ids) { should == [] }
    its(:following_users_count) { should == 0 }
    its(:following_users) { should == [] }
    it { subject.should_not be_following(user2) }
    its(:followers_ids) { should == [] }
    its(:followers_count) { should == 0 }
    its(:followers) { should == []}
    it { subject.should_not be_followed_by(user2)}
  end

  context "when user follows user2" do
    before { user.follow!(user2) }
    its(:following_users_ids) { should == [user2.id] }
    its(:following_users_count) { should == 1 }
    its(:following_users) { should == [user2] }
    it { subject.should be_following(user2) }
    its(:followers_ids) { should == [] }
    its(:followers_count) { should == 0 }
    its(:followers) { should == []}
    it { subject.should_not be_followed_by(user2)}

    context "with user2" do
      subject { user2 }
      its(:following_users_ids) { should == [] }
      its(:following_users_count) { should == 0 }
      its(:following_users) { should == [] }
      it { subject.should_not be_following(user) }
      its(:followers_ids) { should == [user.id] }
      its(:followers_count) { should == 1 }
      its(:followers) { should == [user]}
      it { subject.should be_followed_by(user)}
    end

    context "when user unfollows user2" do
      before { user.unfollow!(user2) }
      its(:following_users_ids) { should == [] }
      its(:following_users_count) { should == 0 }
      its(:following_users) { should == [] }
      it { subject.should_not be_following(user2) }
      its(:followers_ids) { should == [] }
      its(:followers_count) { should == 0 }
      its(:followers) { should == []}
      it { subject.should_not be_followed_by(user2)}
    end
  end

end


describe "bookmarkable" do
  let(:user) { Doable::User.create }
  let(:course) { Doable::Course.create }

  subject { user }

  context "default values" do
    its(:bookmarking_courses_ids) { should == [] }
    its(:bookmarking_courses_count) { should == 0 }
    its(:bookmarking_courses) { should == [] }
    it { subject.should_not be_bookmarking(course) }

    context "with course" do
      subject { course }
      its(:bookmarkers_ids) { should == [] }
      its(:bookmarkers_count) { should == 0 }
      its(:bookmarkers) { should == [] }
      it { subject.should_not be_bookmarked_by(user) }
    end
  end

  context "when a user bookmarks course" do
    before { user.bookmark_course!(course) }

    its(:bookmarking_courses_ids) { should == [course.id] }
    its(:bookmarking_courses_count) { should == 1 }
    its(:bookmarking_courses) { should == [course] }
    it { subject.should be_bookmarking(course) }

    context "with course" do
      subject { course }
      its(:bookmarkers_ids) { should == [user.id] }
      its(:bookmarkers_count) { should == 1 }
      its(:bookmarkers) { should == [user] }
      it { subject.should be_bookmarked_by(user) }
    end

    context "when the same user bookmarks course once more" do
      before { user.bookmark_course!(course) }

      its(:bookmarking_courses_ids) { should == [course.id] }
      its(:bookmarking_courses_count) { should == 1 }
    end

    context "when user unbookmark course" do
      before { user.unbookmark_course!(course) }

      its(:bookmarking_courses_ids) { should == [] }
      its(:bookmarking_courses_count) { should == 0 }
      its(:bookmarking_courses) { should == [] }
      it { subject.should_not be_bookmarking(course) }

      context "with course" do
        subject { course }
        its(:bookmarkers_ids) { should == [] }
        its(:bookmarkers_count) { should == 0 }
        its(:bookmarkers) { should == [] }
        it { subject.should_not be_bookmarked_by(user) }
      end

    end
  end

  context "when user unbookmarks course" do
    before { user.unbookmark_course!(course) }

    its(:bookmarking_courses_ids) { should == [] }
  end

end
