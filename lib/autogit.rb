require 'fileutils'

module Kernel
  def autogit(*args,&blk)
    AutoGit.require_git_repo(*args,&blk)
  end
end

module AutoGit
  
  module StandardDefinition
    def require_git_repo(options)
      urls   = options[:urls] || options[:url] && [options[:url]] or raise ":urls option is required!"
      commit = options[:commit] || options[:tag] || options[:branch] or raise ":commit/:tag/:branch option is required!"
      
      path = clone_one_of_repos!(urls)
      cpath = checkout!(path, commit)
      set_load_path!(cpath)
    end
  end
  
  module LazyDefinition
    def require_git_repo(*args, &blk)
      first  = args[0]
      second = args[1]
      if first.is_a?(String) && second.is_a?(String)
        super(:urls => [first], :commit => second)
      else
        super(*args, &blk)
      end
    end
  end
  
  def base_path
    File.expand_path("~/.autogit")
  end
  
  def clone_name(dir)
    "clone.git"
  end
  
  def checkouts_path
    "checkouts"
  end
  
  def clone_one_of_repos!(urls)
    # TODO: try other repos before giving up
    clone_repo!(urls.first)
  end
  
  def clone_repo!(url)
    url or raise "Cannot clone: no url given!"
    dir = File.join(base_path, pretty_path_for_url(url))
    clone_path = File.join(dir, clone_name(dir))
    FileUtils.mkdir_p(dir)
    unless File.exists?(clone_path)
      unless system("git clone #{url} #{clone_path} --bare")
        FileUtils.rm_rf(clone_path)
        raise "Git clone #{url} -> #{clone_path} failed!"
      end
    end
    clone_path
  end
  
  def checkout!(repo, commit)
    dir = File.dirname(repo)
    cdir = File.join(dir, checkouts_path)
    FileUtils.mkdir_p(cdir)
    cpath = File.join(cdir, commit)
    
    unless File.exists?(cpath)
      unless system("git clone #{repo} #{cpath} --shared")
        FileUtils.rm_rf(cpath)
        raise "Git clone #{repo} -> #{cpath} failed!"
      end
    
      FileUtils.cd(cpath) do |dir|
        unless system("git checkout #{commit}")
          FileUtils.rm_rf(cpath)
          raise "Git checkout #{cdir} -> #{cpath} failed!"
        end
      end
    end
    
    cpath
  end
  
  def set_load_path!(path)
    with_lib = File.join(path, "lib")
    path = File.exists?(with_lib) ? with_lib : path
    $LOAD_PATH.push(path)
    path
  end
  
  def pretty_path_for_url(url)
    url.gsub(%r{(\.git)?/*$},       "").
        gsub(%r{^/},                "blah:///localhost/").
        gsub(%r{^file:/+},          "blah:///localhost/").
        gsub(%r{^\w+:/+},           "").
        gsub(%r{:},                 ".")
  end
  
  include StandardDefinition
  include LazyDefinition
  
  extend self
end


