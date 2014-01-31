#
# GGEnv: Module to deal with environment variables as arrays.
#
# Copyright (c) 2005 Gonzalo Garramuno
# Released under the same terms as Ruby
#
# $Revision: 0.5 $ 
#

require "English"


#
# == Env
#
# == Documentation
#
# This file contains auxiliary routines to easily interact with 
# environment variables that contain lists of paths, like PATH, 
# LD_LIBRARY_PATH, MAYA_SCRIPT_PATH, etc.
#
# == Usage
#
#  Env.check_directories = false       # turn off verification that
#                                      # directories exist (default: true)
#  path = Env['PATH']
#
#  path << "C:/newpath"                # As path is modified, so 
#                                      # is ENV['PATH']
#
#  path.delete_if { |x| x =~ /maya/ }  # remove all paths that have maya
#
#  path.unshift ["C:/", "E:/bin"]      # add these paths at start
#
#  Env['PATH'] = path[0,2] + path[4,6] # concat two slices and send to PATH
#
#  path.check_directories              # check existance of directories
#                                      # for this variable only (unlike
#                                      # Env.check_directories)
#
module Env

  protected
  @@_check_dirs = true
  @@_envvars = {}

  if RUBY_PLATFORM =~ /mswin/
    SEP = ';'
  else
    SEP = ':'
  end

  public
  #
  # Clear the Env path cache to free some memory.
  #
  # == Example
  #
  #    path = Env['PATH']
  #    path = nil
  #    Env.clear
  #
  def self.clear
    @@_envvars = {}
    GC.start
  end

  #
  # Assign a new value (Array or String) to an environment variable.
  #
  # == Example
  #
  #    Env['PATH'] = ['/usr/', '/usr/local/']
  #
  def self.[]=(a, b)
    @@_envvars[a] = EnvVar.new( a, b )
  end

  #
  # Access an environment variable as an array.  
  # The result is cached internally within the Env module for faster
  # access.
  #
  # == Example
  #
  #    puts Env['LD_LIBRARY_PATH']
  #    path = Env['PATH']
  #    path << ["/usr/local/bin"]
  #    path -= "C:/"
  #
  def self.[](a)
    return @@_envvars[a] if @@_envvars[a]
    @@_envvars[a] = EnvVar.new( a, ENV[a] )
  end

  #
  # Are we checking directories of all variables automatically?
  #
  def self.check_directories?
    @@_check_dirs
  end

  #
  # If true, check directories of all Env variables automatically.
  # Default value is true.
  #
  # == Example
  #
  #    Env.check_directories = false
  #    path = Env['PATH']
  #    path << "/inexistent/path/"
  #    puts path
  #    Env.check_directories = true
  #    puts path
  #
  def self.check_directories=(a)
    @@_check_dirs = (a == true)
    if @@_check_dirs
      @@_envvars.each_value { |v| v.check_directories }
    end
  end

  private

  # An auxiliary class that represents environment variable paths 
  # as an array.  User is supposed to interact with this class by simply
  # using Env[VARIABLE] or storing it in a variable.
  class EnvVar < Array
    attr_reader :name

    def initialize(name, value)
      @owner = true
      @name = name
      replace(value) if value
    end

    def replace(value)
      if value.kind_of?(Array)
	super
      elsif value.kind_of?(String)
	super( value.split(SEP) )
      elsif value.kind_of?(NilClass)
	clear; return self
      else
	raise Error, 
	  "Cannot assign #{value} to #{@name}.  Not an array or string."
      end
      uniq!
      map! { |p| unify_path(p) }
      if Env.check_directories?
	check_directories
      else
	to_env
      end
      return self
    end

    def check_directories
      delete_if { |p| not File.directory?(p) }
      to_env
    end

    def clear
      super
      to_env
      return self
    end

    def delete(a, &block)
      super
      to_env
      return self
    end

    def delete_at(a)
      super
      to_env
      return self
    end

    def delete_if(&block)
      super
      to_env
      return self
    end

    def |(b)
      @owner = false
      EnvVar.new( @name, super )
    end
    
    def &(b)
      @owner = false
      EnvVar.new( @name, super )
    end

    def -(b)
      @owner = false
      if b.kind_of?(Array)
	EnvVar.new( @name, super )
      else
	EnvVar.new( @name, super( [b] ) )
      end
    end

    def +(b)
      c = self.dup
      @owner = false
      c << b
    end

    def <<(*b)
      b.each { |p|
	if p.kind_of?(Array)
	  p.each { |x|
	    s = unify_path( x.to_s )
	    next if not verify(s)
	    super(s)
	  }
	  uniq!
	else
	  s = unify_path( p.to_s )
	  next if self.include?(s)
	  next if not verify(s)
	  super(s)
	end
      }
      to_env
      return self
    end

    def push(*b)
      self.<<(*b)
    end

    def remove(b)
      self.delete_if { |p| p =~ /#{b}/ }
      to_env
    end

    def unshift(*b)
      b.reverse_each { |p|
	if p.kind_of?(Array)
	  a = []
	  p.reverse_each { |x|
	    s = unify_path( x.to_s )
	    next if not verify(s)
	    a << s
	  }
	  super(*a)
	  uniq!
	else
	  s = unify_path( p.to_s )
	  next if self.include?(s)
	  next if not verify(s)
	  super(s)
	end
      }
      to_env
    end

    def to_s
      from_env if not @owner
      self.join(SEP)
    end

    def inspect
      to_s
    end

    #
    # Send value of variable to environment
    #
    def to_env
      return if not @name
      from_env if not @owner
      ENV[@name] = to_s
    end

    #
    # Replace value of variable from environment
    #
    def from_env
      return if not @name
      @owner = true
      replace( ENV[@name] )
    end

    protected

    REGEX_DISK     = /^(\w:)\/?/
    REGEX_CYGDRIVE = /^\/cygdrive\/(\w)\/?/
    REGEX_CYGWIN   = /cygwin/
    REGEX_DISK2    = /^([A-Z]):\//

    #
    # Routine used to unify the names of paths to a consistant syntax
    #
    def unify_path(s)
      p = s.frozen? ? s.dup : s
      p.gsub!( /\\/, '/' )
      p = "#{$1.upcase}/#{$POSTMATCH}" if p =~ REGEX_DISK
      if RUBY_PLATFORM =~ REGEX_CYGWIN
	if p =~ REGEX_CYGDRIVE
	  p = "/cygdrive/#{$1.upcase}/#{$POSTMATCH}" 
	else
	  p.sub!( REGEX_DISK2, '/cygdrive/\1/' ) if @name == 'PATH'
	end
      end
      return p
    end

    #
    # Routine used to verify if path is a directory on disk
    #
    def verify(path)
      return false if Env.check_directories? and not File.directory?(path)
      return true
    end
  end

end


if __FILE__ == $0
  Env.check_directories = false

  path = Env['PATH']
  path << [ 'C:', '/' ]

  path.unshift( ['E:', '/etc'] )

  p Env['PATH']
  puts "-- After checking dirs " + '-'*57 
  Env.check_directories = true
  p Env['PATH']

  puts "SLICE: #{path[3,2]}"

  Env['PATH'] = path[0,2] + path[4,1]
  puts "ADD: #{Env['PATH']}"
end
