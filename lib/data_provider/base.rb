require 'logger'

module DataProvider

  class ProviderMissingException < Exception
  end

  module Base

    def self.included(base)
      base.class_eval do
        include InstanceMethods
        extend ClassMethods
      end
    end

    module ClassMethods

      def provides simple_provides = nil
        if simple_provides
          @data_provider ||= {}
          @data_provider[:provides] ||= {}
          @data_provider[:provides].merge!(simple_provides)
        end
        # no data given? just return existing hash
        (@data_provider || {})[:provides] || {}
      end

      def provider identifier, opts = {}, &block
        add_provider(identifier, opts, block_given? ? block : nil)
      end

      def data_provider_definitions
        ((@data_provider || {})[:provider_args] || [])
      end

      def has_provider?(identifier)
        single_provider(identifier) != nil
      end

      def single_provider(id, opts = {})
        args = data_provider_definitions.find{|args| args.first == id}
        return args.nil? ? nil : SingleProvider.new(*args)
      end

      def add(providers_module)
        data = providers_module.instance_variable_get('@data_provider') || {}

        (data[:provider_args] || []).each do |definition|
          add_provider(*definition)
        end
      end

      def add_xml_provider(providers_module, opts = {})
        data = providers_module.instance_variable_get('@data_provider') || {}

        (data[:provider_args] || []).each do |definition|
          definition[0] = [definition[0]].flatten
          definition[0] = [opts[:scope]].flatten.compact + definition[0] if opts[:scope]
          add_provider(*definition)
        end

        (data[:provides] || {}).each_pair do |key, value|
          provides(([opts[:scope]].flatten.compact + [key].flatten.compact) => value)
        end
      end

      private

      def add_provider(identifier, opts = {}, block = nil)
        @data_provider ||= {}
        @data_provider[:provider_args] ||= []
        @data_provider[:provider_args].unshift [identifier, opts, block]
      end
    end # module ClassMethods


    module InstanceMethods

      attr_reader :data
      attr_reader :options

      def initialize(opts = {})
        @options = opts.is_a?(Hash) ? opts : {}
        @data = options[:data].is_a?(Hash) ? options[:data] : {}
      end

      def logger
        @logger ||= options[:logger] || Logger.new(STDOUT)
      end

      def has_provider?(id)
        self.class.has_provider?(id)
      end

      def take(id)
        return self.class.provides[id] if self.class.provides.has_key?(id)
        single_provider = self.class.single_provider(id) #, :data => @data)
        # execute block with the scope of this object
        # if single_provider.nil?
        #   logger.warn "Can't find provider: #{id.inspect}"
        #   return nil
        # end
        raise ProviderMissingException.new(:message=>"Data provider tried to take data from missing provider.", :provider_id => id) if single_provider.nil?
        return instance_eval(&single_provider.block) 
      end

      def try_take(id)
        if !self.has_provider?(id)
          logger.debug "Try for missing provider: #{id.inspect}"
          return nil
        end

        return take(id)
      end

      def given(param_name)
        return data[param_name] if data.has_key?(param_name)
        logger.error "data provider expected missing data with identifier: #{param_name.inspect}"
        # TODO: raise?
        return nil
      end

      alias :get_data :given

      def give(_data = {})
        return self.class.new(options.merge(:data => data.merge(_data)))
      end

      alias :add_scope :give
      alias :add_data :give

      def give!(_data = {})
        @data = data.merge(_data)
        return self
      end

      alias :add_scope! :give!
      alias :add_data! :give!
    end # module InstanceMethods

  end # module Base

end # module DataProvider