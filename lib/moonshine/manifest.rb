require 'puppet'
require 'puppet/dsl'
require 'erb'
gem "activesupport"
require 'active_support/core_ext/class/attribute_accessors'
require 'active_support/inflector'

class Puppet::Util::Log
  @loglevel = 0
end

class Puppet::DSL::Aspect
  def reference(type, title)
    Puppet::Parser::Resource::Reference.new(:type => type.to_s, :title => title.to_s)
  end

  def facts
    Facter.to_hash
  end

  #Create an instance method for every type that either creates or references
  #a resource
  Puppet::Type.loadall
  Puppet::Type.eachtype do |type|
    undef_method(type.name)
    define_method(type.name) do |*args|
      if args && args.flatten.size == 1
        reference(type.name, args.first)
      else
        newresource(type, *args)
      end
    end
  end

end

module Moonshine
  class Manifest
    include Puppet::DSL

    attr_reader :application
    attr_reader :instance_roles
    class_inheritable_accessor :class_roles
    self.class_roles = []

    def initialize(application = nil)
      init
      @application = application
      @instance_roles = []
    end

    def self.role(name, options = {}, &block)
      a = Aspect.new(name, options, &block)
      self.class_roles << a
      a
    end

    def manifest
      self
    end

    def run
      class_role_names = self.class_roles.map { |r| r.name }
      instance_role_names = instance_roles.map { |r| r.name }
      role_names = class_role_names + instance_role_names
      apply_roles(*role_names) if role_names
    end

    def role(name, options = {}, &block)
      a = Aspect.new(name, options, &block)
      @instance_roles << a
      a
    end

    def apply_roles(*names)
      acquire(*names)
      apply
    end

  end

end

Dir.glob(File.join(File.dirname(__FILE__), '..', 'facts', '*.rb')).each do |fact|
  require fact
end
Dir.glob(File.join(File.dirname(__FILE__), 'modules', '*.rb')).each do |mod|
  require mod
end
Dir.glob(File.join(File.dirname(__FILE__), 'manifest', '*.rb')).each do |manifest|
  require manifest
end