module PaperTrailScrapbook
  # Class Changes provides detailed attribute by attribute analysis
  #
  # @author Timothy Chambers <tim@possibilogy.com>
  #
  class Changes
    include Concord.new(:version)
    include Adamantium::Flat

    def initialize(*)
      super
      build_associations
      changes
    end

    BULLET = ' •'.freeze

    # Attribute change analysis
    #
    #
    # @return [String] Summary analysis of changes
    #
    def change_log
      text = changes
             .map { |k, v| digest(k, v) }
             .compact
             .join("\n")

      text = text.gsub(' id:', ':') if PaperTrailScrapbook.config.drop_id_suffix
      text
    end

    private

    def digest(k, v)
      old, new = v
      return if old.nil? && (new.nil? || new.eql?(''))

      "#{BULLET} #{k.tr('_', ' ')}: #{detailed_analysis(k, new, old)}"
    end

    def detailed_analysis(k, new, old)
      if creating?
        find_value(k, new).to_s
      elsif old.nil?
        "#{find_value(k, new)} added"
      elsif new.nil?
        "#{find_value(k, old)} was *removed*"
      else
        "#{find_value(k, old)} -> #{find_value(k, new)}"
      end
    end

    def creating?
      version.event.eql?('create')
    end

    def find_value(key, value)
      return value.to_s unless assoc.key?(key)

      return '*empty*' unless value

      begin
        assoc[key].find(value).to_s.to_s + "[#{value}]"
      rescue StandardError
        "*not found*[#{value}]"
      end
    end

    def assoc_klass(name, options = {})
      direct_class = options[:class_name]
      return direct_class if direct_class && !direct_class.is_a?(String)

      Object.const_get((direct_class || name.to_s).classify)
    rescue StandardError
      Object.const_set(name.to_s.classify, Class.new)
    end

    def klass
      assoc_klass(version.item_type)
    end

    def build_associations
      @assoc ||=
        Hash[
          klass
        .reflect_on_all_associations
        .select { |a| a.macro.equal?(:belongs_to) }
        .map { |x| [x.foreign_key.to_s, assoc_klass(x.name, x.options)] }
        ]
    end

    def object_changes
      version.object_changes
    end

    def changes
      @chs ||= if object_changes
                 YAML
                   .load(object_changes)
                   .except(*PaperTrailScrapbook.config.scrub_columns)
               else
                 {}
               end
    end

    attr_reader :assoc, :chs
  end
end
