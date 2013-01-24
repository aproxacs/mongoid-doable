# mongoid-doable

While I was working with rails and mongoid, the functions like below was necessary.
  
    user.like(comment)
    user.bookmark(course)
    user.register(course)
    user.follow(another_user)

While implementing these functions, I found that they all do the same thing in the model, they just have a different expression. So the mongoid-doable came out.


# Installation
#### Using Gem
  
    gem install mongoid-doable

#### Using bundler
  
    gem 'mongoid-doable'


# Examples

    class Course
      include Monogid::Document
      include Monogid::Doable
      doable :like, by: :user
    end
    class User
      include Monogid::Document
      include Monogid::Doable
      doer :like, :course
    end

    user = User.create
    course = Course.create

    user.like!(course) # or
    user.like_course!(course) # or
    course.liked_by!(user) # or

    user.liking_courses
    user.liking_courses_count

    course.likers
    course.likers_count

    

# Contributing to mongoid-doable
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
* Fork the project.
* Start a feature/bugfix branch.
* Commit and push until you are happy with your contribution.
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

== Copyright

Copyright (c) 2013 aproxacs. See LICENSE.txt for
further details.

