module Mongoid
  module Doable
    extend ActiveSupport::Concern

    included do |base|      
    end

    module ClassMethods
      # Examples
      #   class Course
      #     include Monogid::Document
      #     include Monogid::Doable
      #
      #     doable :like, by: :user
      #   end
      #
      #   class User
      #     include Monogid::Document
      #     include Monogid::Doable
      #
      #     doer :like, :course
      #
      #     doable :follow, by: :user
      #     doer :follow, :user
      #   end
      #
      #   user = User.first
      #   course = Course.first
      #
      #   user.like!(course) # or
      #   user.like_course!(course) # or
      #   course.liked_by!(user) # or
      #
      #   user.liking_courses
      #   user.liking_courses_count
      #
      #   course.likers
      #   course.likers_count
      #

      def doable(action, options = {})
        doer_klass_names[action.to_sym] = (options[:by] || :user).to_s.classify

        action = action.to_s                                          # "like"
        base_action = (action[-1] == "e" ? action.chop : action)      # "lik"
        passive_action = base_action + "ed"                           # "liked"
        doer_action = base_action + "ers"                             # "likers"

        field_name = "#{doer_action}_ids"                             # "likers_ids"
        counter_field_name = "#{doer_action}_count"                   # "likers_count"
        field field_name, type: Array, default: [], versioned: false          # field :likers_ids, type: Array, default: [], versioned: false
        field counter_field_name, type: Integer, default: 0, versioned: false # field :likers_count, type: Integer, default: 0, versioned: false

        define_method "#{doer_action}" do                                 # def likers
          klass = self.class.doer_klass_names[action.to_sym].constantize  #   klass = User
          klass.where(:"_id".in => send(field_name))                      #   klass.where(:likers_ids.in => likers_ids)
        end                                                               # end

        define_method "#{passive_action}_by?" do |actor|              # def liked_by?(actor)
          return false if actor.blank?                                #   return false if actor.blank?
          send(field_name).include? actor.id                          #   likers_ids.include? actor.id
        end                                                           # end

        define_method "#{passive_action}_by!" do |actor|              # def liked_by!(actor)
          return false if actor.blank?                                #   return false if actor.blank?          
          if actor.respond_to?("#{action}!")                          #   if actor.respond_to?(:like!)
            actor.send("#{action}!", self)                            #     actor.like!(self) 
          else                                                        #   else
            add_to_set(field_name, actor.id)                          #     self.add_to_set(:liker_ids, actor.id)  
            inc(counter_field_name.to_sym, 1)                         #     inc(:likers_count, 1)
          end                                                         #   end          
        end                                                           # end

        define_method "un#{passive_action}_by!" do |actor|            # def unliked_by!(actor)
          return false if actor.blank?                                #   return false if actor.blank?          
          if actor.respond_to?("un#{action}!")                        #   if actor.respond_to?(:unlike!)
            actor.send("un#{action}!", self)                          #     actor.unlike!(self) 
          else                                                        #   else
            pull(field_name, actor.id)                                #     self.pull(:liker_ids, actor.id)
            inc(counter_field_name.to_sym, -1)                        #     inc(:likers_count, -1)
          end                                                         #   end
        end                                                           # end
      end

      def doer(action, target, options = {})

        action = action.to_s                                                # "like"
        base_action = (action[-1] == "e" ? action.chop : action)            # "lik"
        ing_action = base_action + "ing"                                    # "liking"
        passive_action = base_action + "ed"                                 # "liked"
        doer_action = base_action + "ers"                                   # "likers"
      
        field_name = "#{ing_action}_#{target.to_s.pluralize}_ids"           # "liking_courses_ids"
        target_field_name = "#{doer_action}_ids"                            # "likers_ids"
        target_counter_name = "#{doer_action}_count"                        # "likers_count"
        klass_name = options[:class_name] || target.to_s.classify           # "Course"

        field field_name, type: Array, default: [], versioned: false        # field :liking_courses_ids, type Array, default: [], versioned: false

        define_method "#{ing_action}_#{target.to_s.pluralize}_count" do     # def liking_courses_count
          send(field_name).size                                             #   liking_courses_ids.size
        end                                                                 # end

        unless options[:embedded]
          define_method "#{ing_action}_#{target.to_s.pluralize}" do         # def liking_courses
            klass_name.constantize.where(:"_id".in => send(field_name))     #   Course.where(:liking_courses_ids.in => liking_courses_ids)
          end                                                               # end
        end


        unless method_defined? "#{ing_action}?"
          define_method "#{ing_action}?" do |model|                         # def liking?(course)
            field = model.class.name.split(":").last.downcase               #   
            send("#{ing_action}_#{field}?", model)                          #   liking_course?(course)
          end                                                               # end
        end

        define_method "#{ing_action}_#{target}?" do |model|                 # def liking_course?(course)
          send(field_name).include?(model.id)                               #   liking_courses_ids.include?(course.id)
        end                                                                 # end

        unless method_defined? "#{action}!"
          define_method "#{action}!" do |model|                                                   # def like!(couse)
            field = model.class.name.split(":").last.downcase                                     #   
            send("#{action}_#{field}!", model)                                                    #   like_course!(course)
          end                                                                                     # end
        end

        define_method "#{action}_#{target}!" do |model|                                           # def like_course!(course)
          return if send("#{ing_action}_#{target}?", model)                                       #   return if liking_course?(course)

          model.add_to_set(target_field_name, self.id) if model.respond_to?(target_field_name)    #   course.add_to_set(:likers_ids, self.id) if model.respond_to?(:likers_ids)
          model.inc(target_counter_name, 1)                                                       #   coruse.inc(:likers_ids, 1)
          add_to_set(field_name, model.id)                                                        #   add_to_set(:liking_courses_ids, course.id)
        end                                                                                       # end


        unless method_defined? "un#{action}!"
          define_method "un#{action}!" do |model|                                                 # def unlike!(course)
            field = model.class.name.split(":").last.downcase                                     #   
            send("un#{action}_#{field}!", model)                                                  #   like_course!(course)
          end                                                                                     # end
        end

        define_method "un#{action}_#{target}!" do |model|                                         # def unlike_course!(course)
          return unless send("#{ing_action}_#{target}?", model)                                   #   return unless liking_course?(course)

          model.pull(target_field_name, self.id) if model.respond_to?(target_field_name)          #   course.pull(:likers_ids, self.id) if course.respond_to?(:likers_ids)
          model.inc(target_counter_name, -1)                                                      #   course.inc(likers_ids, -1)
          self.pull(field_name, model.id)                                                         #   self.pull(:liking_courses_ids)
        end                                                                                       # end

      end

      def doer_klass_names                                                   # def doer_klass_names
        @doer_klass_names ||= {}                                             #   @doer_klass_names ||= {}
      end                                                               # end

    end

  end
end

