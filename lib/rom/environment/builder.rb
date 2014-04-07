# encoding: utf-8

require 'addressable/uri'

require 'rom/environment'
require 'rom/repository'
require 'rom/schema/builder'
require 'rom/mapper/builder'

module ROM

  # The environment configures repositories and loads schema with relations
  #
  class Environment

    # Environment builder DSL
    #
    class Builder
      attr_reader :repositories, :relations, :mappers

      # @api private
      def self.call(config)
        repositories = config.each_with_object({}) { |(name, uri), hash|
          hash[name.to_sym] = Repository.build(name, Addressable::URI.parse(uri))
        }

        new(repositories)
      end

      # @api private
      def initialize(repositories)
        @repositories = repositories
        @relations = {}
        @schema = Schema::Builder.build(repositories)
        @mappers = Mapper::Builder.new(schema)
      end

      # @api private
      def schema(&block)
        @schema.call(&block) if block
        @schema
      end

      # @api private
      def mapping(&block)
        mappers.call(&block)
      end

      # @api private
      def [](name)
        relations[name]
      end

      # @api private
      def []=(name, relation)
        relations[name] = relation
      end

      # @api private
      def finalize
        mappers.each do |name, mapper|
          relations[name] = Relation.new(schema[name], mapper)
        end

        Environment.new(repositories, schema.finalize, relations, mappers.finalize)
      end

    end # Builder

  end # Environment
end # ROM