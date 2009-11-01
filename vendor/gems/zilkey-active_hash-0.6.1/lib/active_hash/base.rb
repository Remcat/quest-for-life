module ActiveHash
  class Base
    class_inheritable_accessor :data
    class << self
      attr_reader :field_names

      def data=(array_of_hashes)
        @records = nil
        write_inheritable_attribute(:data, array_of_hashes)
      end

      def all
        unless @records
          records = read_inheritable_attribute(:data) || []
          @records = records.collect {|hash| new(hash)}
          auto_assign_fields( records )
        end
        @records
      end

      def count
        all.length
      end

      def find(id, *args)
        case id
          when :all
            all
          when Array
            all.select {|record| id.map(&:to_i).include?(record.id) }
          else
            find_by_id(id)
        end
      end

      def find_by_id(id)
        all.detect {|record| record.id == id.to_i}
      end

      delegate :first, :last, :to => :all

      def fields(*args)
        options = args.extract_options!
        args.each do |field|
          field(field, options)
        end
      end

      def field(field_name, options = {})
        @field_names ||= []
        @field_names << field_name

        define_getter_method(field_name, options[:default])
        define_interrogator_method(field_name)
        define_custom_find_method(field_name)
        define_custom_find_all_method(field_name)
      end

      def respond_to?(method_name)
        super ||
          begin
            config = configuration_for_custom_finder(method_name)
            config && config[:fields].all? { |field| field_names.include?(field.to_sym) }
          end
      end

      def method_missing(method_name, *args)
        return super unless respond_to? method_name

        config = configuration_for_custom_finder(method_name)
        attribute_pairs = config[:fields].zip(args)
        matches = all.select { |base| attribute_pairs.all? { |field, value| base.send(field) == value } }
        config[:all?] ? matches : matches.first
      end

      def configuration_for_custom_finder(finder_name)
        if finder_name.to_s.match(/^find_(all_)?by_(.*)/)
          {
            :all?   => !!$1,
            :fields => $2.split('_and_')
          }
        end
      end

      def define_getter_method(field, default_value)
        unless instance_methods.include?(field.to_s)
          define_method(field) do
            attributes[field] || default_value
          end
        end
      end

      private :define_getter_method

      def define_interrogator_method(field)
        method_name = "#{field}?"
        unless instance_methods.include?(method_name)
          define_method(method_name) do
            attributes[field].present?
          end
        end
      end

      private :define_interrogator_method

      def define_custom_find_method(field_name)
        method_name = "find_by_#{field_name}"
        unless singleton_methods.include?(method_name)
          metaclass.instance_eval do
            define_method(method_name) do |name|
              all.detect {|record| record.send(field_name) == name }
            end
          end
        end
      end

      private :define_custom_find_method

      def define_custom_find_all_method(field_name)
        method_name = "find_all_by_#{field_name}"
        unless singleton_methods.include?(method_name)
          metaclass.instance_eval do
            unless singleton_methods.include?(method_name)
              define_method(method_name) do |name|
                all.select {|record| record.send(field_name) == name }
              end
            end
          end
        end
      end

      private :define_custom_find_all_method

      def auto_assign_fields(array_of_hashes)
        array_of_hashes.inject([]) do |array, row|
          row.symbolize_keys!
          row.keys.each do |key|
            unless key.to_s == "id"
              array << key
            end
          end
          array
        end.uniq.each do |key|
          field key
        end
      end

      private :auto_assign_fields

    end

    attr_reader :attributes

    def initialize(options = {})
      options.symbolize_keys!
      @attributes = options
    end

    def id
      attributes[:id] ? attributes[:id].to_i : nil
    end

    alias quoted_id id

    def new_record?
      false
    end

    def readonly?
      true
    end

    def to_param
      id.to_s
    end

    def eql?(other)
      other.instance_of?(self.class) and not id.nil? and (id == other.id)
    end

    alias == eql?

    def hash
      id.hash
    end

  end
end
