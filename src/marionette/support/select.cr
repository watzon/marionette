module Marionette
  module Support
    class Select
      private getter element : Element
      private getter multi : Bool

      #
      # @param [Element] element The select element to use
      #

      def initialize(element : Element)
        tag_name = element.tag_name

        raise ArgumentError.new("unexpected tag name #{tag_name.inspect}") unless tag_name.downcase == "select"

        @element = element
        @multi = ![nil, "false"].includes?(element.dom_attribute(:multiple))
      end

      #
      # Does this select element support selecting multiple options?
      #
      # @return [Boolean]
      #

      def multiple?
        @multi
      end

      #
      # Get all options for this select element
      #
      # @return [Array<Element>]
      #

      def options
        @element.find_children("option", strategy: :tag_name)
      end

      #
      # Get all selected options for this select element
      #
      # @return [Array<Element>]
      #

      def selected_options
        options.select(&.selected?)
      end

      #
      # Get the first selected option in this select element
      #
      # @raise [Error::NoSuchElementError] if no options are selected
      # @return [Element]
      #

      def first_selected_option
        option = options.find(&.selected?)
        return option if option
        raise Error::NoSuchElementError.new "no options are selected"
      end

      #
      # Select options by visible text, index or value.
      #
      # When selecting by :text, selects options that display text matching the argument. That is, when given "Bar" this
      # would select an option like:
      #
      #     <option value="foo">Bar</option>
      #
      # When slecting by :value, selects all options that have a value matching the argument. That is, when given "foo" this
      # would select an option like:
      #
      #     <option value="foo">Bar</option>
      #
      # When selecting by :index, selects the option at the given index. This is done by examining the "index" attribute of an
      # element, and not merely by counting.
      #
      # @param [:text, :index, :value] how How to find the option
      # @param [String] what What value to find the option by.
      #

      def select_by(how, what)
        case how
        when :text
          select_by_text what
        when :index
          select_by_index what
        when :value
          select_by_value what
        else
          raise ArgumentError.new("can't select options by #{how.inspect}")
        end
      end

      #
      # Deselect options by visible text, index or value.
      #
      # @param [:text, :index, :value] how How to find the option
      # @param [String] what What value to find the option by.
      # @raise [Error::UnsupportedOperationError] if the element does not support multiple selections.
      #
      # @see Select#select_by
      #

      def deselect_by(how, what)
        case how
        when :text
          deselect_by_text what
        when :value
          deselect_by_value what
        when :index
          deselect_by_index what
        else
          raise ArgumentError.new("can't deselect options by #{how.inspect}")
        end
      end

      #
      # Select all unselected options. Only valid if the element supports multiple selections.
      #
      # @raise [Error::UnsupportedOperationError] if the element does not support multiple selections.
      #

      def select_all
        raise Error::UnsupportedOperationError.new("you may only select all options of a multi-select") unless multiple?
        options.each { |e| select_option e }
      end

      #
      # Deselect all selected options. Only valid if the element supports multiple selections.
      #
      # @raise [Error::UnsupportedOperationError] if the element does not support multiple selections.
      #

      def deselect_all
        raise Error::UnsupportedOperationError.new("you may only deselect all options of a multi-select") unless multiple?
        options.each { |e| deselect_option e }
      end

      private def select_by_text(text)
        opts = find_by_text text

        return select_options(opts) unless opts.empty?

        raise Error::NoSuchElementError.new("cannot locate element with text: #{text.inspect}")
      end

      private def select_by_index(index)
        opts = find_by_index index

        return select_option(opts.first) unless opts.empty?

        raise Error::NoSuchElementError.new("cannot locate element with index: #{index.inspect}")
      end

      private def select_by_value(value)
        opts = find_by_value value

        return select_options(opts) unless opts.empty?

        raise Error::NoSuchElementError.new("cannot locate option with value: #{value.inspect}")
      end

      private def deselect_by_text(text)
        raise Error::UnsupportedOperationError.new("you may only deselect option of a multi-select") unless multiple?

        opts = find_by_text text

        return deselect_options(opts) unless opts.empty?

        raise Error::NoSuchElementError.new "cannot locate element with text: #{text.inspect}"
      end

      private def deselect_by_value(value)
        raise Error::UnsupportedOperationError.new("you may only deselect option of a multi-select") unless multiple?

        opts = find_by_value value

        return deselect_options(opts) unless opts.empty?

        raise Error::NoSuchElementError.new("cannot locate option with value: #{value.inspect}")
      end

      private def deselect_by_index(index)
        raise Error::UnsupportedOperationError.new("you may only deselect option of a multi-select") unless multiple?

        opts = find_by_index index

        return deselect_option(opts.first) unless opts.empty?

        raise Error::NoSuchElementError.new("cannot locate option with index: #{index}")
      end

      private def select_option(option)
        option.click unless option.selected?
      end

      private def deselect_option(option)
        option.click if option.selected?
      end

      private def select_options(opts)
        if multiple?
          opts.each { |o| select_option o }
        else
          select_option opts.first
        end
      end

      private def deselect_options(opts)
        if multiple?
          opts.each { |o| deselect_option o }
        else
          deselect_option opts.first
        end
      end

      private def find_by_text(text)
        xpath = ".//option[normalize-space(.) = #{Escaper.escape text}]"
        opts = @element.find_children(xpath, strategy: :x_path)

        return opts unless opts.empty? && /\s+/.match?(text)

        longest_word = text.split(/\s+/).max_by(&.length)
        if longest_word.empty?
          candidates = options
        else
          xpath = ".//option[contains(., #{Escaper.escape longest_word})]"
          candidates = @element.find_elements(xpath: xpath)
        end

        return candidates.find { |option| text == option.text } unless multiple?

        candidates.select { |option| text == option.text }
      end

      private def find_by_index(index)
        options.select { |option| option.property(:index) == index }
      end

      private def find_by_value(value)
        @element.find_elements(xpath: ".//option[@value = #{Escaper.escape value}]")
      end
    end
  end
end
