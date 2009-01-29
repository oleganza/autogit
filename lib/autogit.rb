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
    "~/.autogit"
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
    dir = File.expand_path(File.join(base_path, pretty_path_for_url(url)))
    clone_path = File.join(dir, clone_name(dir))
    FileUtils.mkdir_p(dir)
    unless File.exists?(clone_path)
      unless system("git clone #{url} #{clone_path} --no-checkout")
        FileUtils.rm_rf(clone_path)
        raise "Git clone #{url} -> #{clone_path} failed!"
      end
    end
    clone_path
  end
  
  def checkout!(repo, commit, try_pull = true)
    _pwd = Dir.pwd
    
    dir = File.dirname(repo)
    cdir = File.join(dir, checkouts_path)
    FileUtils.mkdir_p(cdir)
    cpath = File.join(cdir, commit)
    
    unless File.exists?(cpath)
      unless system("git clone #{repo} #{cpath} --shared")
        FileUtils.rm_rf(cpath)
        raise "Git clone #{repo} -> #{cpath} failed!"
      end
    
      Dir.chdir(cpath)
      
      unless system("git checkout #{commit}")
        FileUtils.rm_rf(cpath)
        # pull bare repo, try to checkout again
        if try_pull
          $stderr.puts "Failed to checkout #{commit}: trying to fetch updates for #{repo}..."
          Dir.chdir(repo)
          
          unless system("git fetch")
            raise "Git fetch inside #{repo} failed!"
          end
          
          cpath = checkout!(repo, commit, false)
          $stderr.puts "Fetched #{commit}."
        else
          raise "Git checkout #{repo} -> #{commit} failed!"
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
  
  def pretty_path_for_url(url)
    url.gsub(%r{(\.git)?/*$},       "").
        gsub(%r{^/},                "blah:///localhost/").
        gsub(%r{^file:/+},          "blah:///localhost/").
        gsub(%r{^\w+:/+},           "").
        gsub(%r{:},                 ".").
        gsub(%r{/},                 "-")
  end
  
end


