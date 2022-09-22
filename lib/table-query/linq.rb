module TableQuery
  module LINQ
    class Query
      include Enumerable

      def initialize(source)
        @data_source = source
      end

      attr_reader :data_source

      def where(&block)
        Where.new(self, &block)
      end

      def select(&block)
        Select.new(self, &block)
      end

      def group_by(&block)
        Group.new(self, &block)
      end

      def each(&block)
        @data_source.each(&block)
      end
    end

    class From < Query
      def initialize(name, source)
        super(source)
        @data_source_name = name
      end

      attr_reader :data_source_name
    end

    class Where < Query
      def initialize(source, &block)
        super(source)
        @condition = instance_eval(&block)
      end

      def data_source_name
        @data_source.data_source_name
      end

      def method_missing(name, *args)
        if name == data_source_name
          Placeholder.new(name)
        else
          super
        end
      end

      def each
        @data_source.each do |item|
          if @condition.evaluate(data_source_name => item)
            yield item
          end
        end
      end
    end

    class Select < Query
      def initialize(source, &block)
        super(source)
        @expr = Expr.create(instance_eval(&block))
      end

      def data_source_name
        @data_source.data_source_name
      end

      def method_missing(name, *args)
        if name == data_source_name
          Placeholder.new(name)
        else
          super
        end
      end

      def each(&block)
        @data_source.each do |item|
          yield @expr.evaluate(data_source_name => item)
        end
      end
    end

    class Group < Query
      def initialize(source, &block)
        super(source)
        @expr = instance_eval(&block)
      end

      def data_source_name
        @data_source.data_source_name
      end

      def method_missing(name, *args)
        if name == data_source_name
          Placeholder.new(name)
        else
          super
        end
      end

      def each(&block)
        @data_source.each.group_by { |item|
          @expr.evaluate(data_source_name => item)
        }.each(&block)
      end
    end

    class Expr
      def self.create(arg)
        case arg
        when Expr
          arg
        when Symbol
          Placehlder.new(arg)
        when Numeric, String
          Constant.new(arg)
        when Hash
          HashValue.new(arg)
        else
          raise ArgumentError, "Unsupported data type: #{arg.class}"
        end
      end

      def >(arg)
        arg = Expr.create(arg)
        GreaterThan.new(self, arg)
      end

      def [](*args)
        ArrayRef.new(self, args)
      end

      def method_missing(name, *args, &block)
        MethodCall.new(self, name, args, block)
      end
    end

    class ArrayRef < Expr
      def initialize(expr, index)
        @expr = expr
        @index = index
      end

      def evaluate(mapping)
        @expr.evaluate(mapping)[*@index]
      end
    end

    class Constant < Expr
      def initialize(value)
        @value = value
      end

      def evaluate(*)
        @value
      end
    end

    class HashValue < Expr
      def initialize(value)
        @value = value
      end

      def evaluate(mappings)
        @value.transform_values do |v|
          case v
          when Expr
            v.evaluate(mappings)
          else
            v
          end
        end
      end
    end

    class MethodCall < Expr
      def initialize(recv, name, args, block)
        @recv = recv
        @name = name
        @args = args.map {|a| Expr.create(a) }
        @block = block
      end

      def evaluate(mappings)
        values = @args.map {|a| a.evaluate(mappings) }
        @recv.evaluate(mappings).send(@name, *values, &@block)
      end
    end

    class Placeholder < Expr
      def initialize(name)
        @name = name
      end

      def data_source_name
        name
      end

      def evaluate(mapping)
        mapping[@name]
      end
    end

    class GreaterThan < Expr
      def initialize(left, right)
        @left = left
        @right = right
      end

      def evaluate(mapping)
        @left.evaluate(mapping) > @right.evaluate(mapping)
      end
    end
  end

  def self.from(name, in:)
    source = binding.local_variable_get(:in)
    LINQ::From.new(name, source)
  end
end
