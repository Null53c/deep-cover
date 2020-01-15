# frozen_string_literal: true

require_relative 'begin'
require_relative 'variables'
require_relative 'collections'
module DeepCover
  class Node
    def simple_literal?
      false
    end

    class StaticLiteral < Node
      executed_loc_keys :expression

      def simple_literal?
        true
      end
    end

    # Singletons
    class SingletonLiteral < StaticLiteral
    end
    True = False = Nil = Self = SingletonLiteral

    # Atoms
    def self.atom(type)
      ::Class.new(StaticLiteral) do
        has_child value: type
      end
    end
    Sym = atom(::Symbol)
    Int = atom(::Integer)
    Float = atom(::Float)
    Complex = atom(::Complex)
    Rational = atom(::Rational)
    class Regopt < StaticLiteral
      has_extra_children options: [::Symbol]
    end

    class Str < StaticLiteral
      has_child value: ::String

      def executed_loc_keys
        keys = [:expression, :heredoc_body, :heredoc_end]

        exp = expression
        keys.delete(:expression) if exp && exp.source !~ /\S/

        hd_body = loc_hash[:heredoc_body]
        keys.delete(:heredoc_body) if hd_body && hd_body.source !~ /\S/

        keys
      end
    end

    # (Potentially) dynamic
    module SimpleIfItsChildrenAre
      def simple_literal?
        children.all?(&:simple_literal?)
      end
    end

    # Di-atomic
    class Range < Node
      include SimpleIfItsChildrenAre
      include ExecutedAfterChildren

      has_child from: Node
      has_child to: Node
    end
    Erange = Irange = Range

    # Dynamic
    def self.has_evaluated_segments
      has_extra_children constituents: [Str, Begin, Ivar, Cvar, Gvar, Dstr, NthRef]
    end
    class DynamicLiteral < Node
      def executed_loc_keys
        if loc_hash[:heredoc_end]
          [:expression, :heredoc_end]
        else
          [:begin, :end]
        end
      end
    end
    Dsym = Dstr = DynamicLiteral
    DynamicLiteral.has_evaluated_segments

    class Regexp < Node
      include SimpleIfItsChildrenAre

      has_evaluated_segments
      has_child option: Regopt
    end

    class Xstr < Node
      check_completion
      has_evaluated_segments
    end
  end
end
