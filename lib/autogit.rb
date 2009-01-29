require 'fileutils'

module Kernel
  def autogit(*args,&blk)
    AutoGit.require_git_repo(*args,&blk)
  end
end

module AutoGit extend self
  
  def require_git_repo(urls, commit)
    urls = [urls] if urls.is_a?(String)
    path = clone_one_of_repos!(urls)
    cpath = checkout!(path, commit)
    set_load_path!(cpath)
  end
  
  def base_path
    (@base_path || ENV['AUTOGIT_BASE_PATH'] || "~/.autogit")
  end
  
  def clone_one_of_repos!(urls)
    path = urls.map{|u| clone_path_for_url(u) }.detect{|p| File.exists?(p)} and return path
    url = urls.shift
    begin
      clone_repo!(url)
    rescue CloneError
      url = urls.shift and retry or raise
    end
  end
  
  def clone_path_for_url(url)
    dir = File.expand_path(File.join(base_path, pretty_path_for_url(url)))
    File.join(dir, "clone")
  end
  
  def clone_repo!(url)
    clone_path = clone_path_for_url(url)
    FileUtils.mkdir_p(File.dirname(clone_path))
    clone!(url, clone_path, "--no-checkout") unless File.exists?(clone_path)
    clone_path
  end
  
  def checkout!(repo, commit, try_pull = true)
    _pwd = Dir.pwd
    
    dir = File.dirname(repo)
    cdir = File.join(dir, "checkouts")
    FileUtils.mkdir_p(cdir)
    cpath = File.join(cdir, commit)
    
    unless File.exists?(cpath)
      clone!(repo, cpath, "--shared")
          
      Dir.chdir(cpath)
      unless system("git checkout #{commit}")
        FileUtils.rm_rf(cpath)
        # pull bare repo, try to checkout again
        if try_pull
          $stderr.puts "Failed to checkout #{commit}: trying to fetch updates for #{repo}..."
          Dir.chdir(repo)
          system("git fetch") or raise(FetchError, "Git fetch inside #{repo} failed!")
          cpath = checkout!(repo, commit, false)
        else
          raise CheckoutError, "Git checkout #{repo} -> #{commit} failed!"
        end
      end
    end
    
    cpath
  ensure
    Dir.chdir(_pwd)
  end
  
  def set_load_path!(path)
    with_lib = File.join(path, "lib")
    path = File.exists?(with_lib) ? with_lib : path
    $LOAD_PATH.push(path)
    path
  end
  
  def clone!(from, to, opts = "")
    unless system("git clone #{from} #{to} #{opts}")
      FileUtils.rm_rf(to)
      raise CloneError, "Git clone #{from} -> #{to} failed!"
    end
  end
  
  def pretty_path_for_url(url)
    url.gsub(%r{(\.git)?/*$},       "").
        gsub(%r{^/},                "blah:///localhost/").
        gsub(%r{^file:/+},          "blah:///localhost/").
        gsub(%r{^\w+:/+},           "").
        gsub(%r{:},                 ".").
        gsub(%r{/},                 "-")
  end
  
  class CloneError < StandardError; end
  class FetchError < StandardError; end
  class CheckoutError < StandardError; end
end
