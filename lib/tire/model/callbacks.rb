module Tire
  module Model

    mattr_accessor :searchable_models
    @@searchable_models = []

    # Main module containing the infrastructure for automatic updating
    # of the _Elasticsearch_ index on model instance create, update or delete.
    #
    # Include it in your model: `include Tire::Model::Callbacks`
    #
    # The model must respond to `after_save` and `after_destroy` callbacks
    # (ActiveModel and ActiveRecord models do so, by default).
    #
    module Callbacks

      # A hook triggered by the `include Tire::Model::Callbacks` statement in the model.
      #
      def self.included(base)

        Tire::Model.searchable_models << base

        base.class_attribute :disable_es
        base.disable_es = false
        base.define_singleton_method :disable_es_callbacks, -> { self.disable_es = true }
        base.define_singleton_method :enable_es_callbacks, -> { self.disable_es = false }

        # Update index on model instance change or destroy.
        #
        if base.respond_to?(:after_save) && base.respond_to?(:after_destroy)
          base.send :after_save,    lambda { tire.update_index unless base.disable_es }
          base.send :after_destroy, lambda { tire.update_index unless base.disable_es }
        end

        # Add neccessary infrastructure for the model, when missing in
        # some half-baked ActiveModel implementations.
        #
        if base.respond_to?(:before_destroy) && !base.instance_methods.map(&:to_sym).include?(:destroyed?)
          base.class_eval do
            before_destroy  { @destroyed = true }
            def destroyed?; !!@destroyed; end
          end
        end

      end
    end

    def self.disable_all_es_callbacks
      searchable_models.each { |model| model.disable_es_callbacks }
    end

    def self.enable_all_es_callbacks
      searchable_models.each { |model| model.enable_es_callbacks }
    end
  end
end
