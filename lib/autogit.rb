require 'fileutils'

module Kernel
  # Global shortcut to AutoGit.require_git_repo
  def autogit(*args,&blk)
    AutoGit.require_git_repo(*args,&blk)
  end
end

module AutoGit extend self
  
  # Clone a repository, checkout specific commit and add it to the $LOAD_PATH
  # * urls can be a list of URLs or a single URL. 
  # * for list of URLs, AutoGit tries to clone the first accessible URL.
  # * commit is a valid git commitish (that is: commit, tag or a branch name)
  # * method does nothing if the list of URLs is empty (or nil)
  # * method returns path to checked out commit (path is appended to $LOAD_PATH)
  # 
  # Examples:
  #   autogit "git://github.com/oleganza/autogit.git", "c8f549fea063eacd"
  #   autogit [github, myserver, localfolder], "1.0"
  #
  def require_git_repo(urls, commit)
    urls = filter_urls(rewrite_rules, [urls].flatten.compact)
    return if urls.empty?
    set_load_path!(
      checkout!(
        clone_one_of_repos!(urls), 
          commit)
            )
  end
  
  # Define a rewrite rule for source URL. 
  # * Block can return nil to throw URL from the list, single URL or a list of URLs.
  # * You can specify any number of rules to reject or redirect particular URLs.
  # * Rules are applied in reverse order (so you have complete control on what URLs dependency uses)
  # 
  # Example: 
  #   # Add local mirror for github urls:
  #   AutoGit.rewrite(%r{git://github.com/([^/]+)/([^/]+)}) do |url, user, project|
  #     [url, "/var/github-mirror/#{user}-#{project}"]
  #   end
  #
  #   # Reject bad URL:
  #   AutoGit.rewrite(%r{badurl}, nil)
  #
  def rewrite(regexp, value = nil, &blk)
    rewrite_rules.unshift(RewriteRule.new(regexp, blk || proc{|*_| value }))
  end
  
  # Specify base folder for storing cloned repositories.
  # You can override default value (~/.autogit) using AUTOGIT_BASE_PATH environment variable or
  # accessor: AutoGit.base_path = "/some/path"
  attr_accessor :base_path
  def base_path
    @base_path || ENV['AUTOGIT_BASE_PATH'] || "~/.autogit"
  end
  
  # 
  # Private API
  #
  
  def clone_one_of_repos!(urls)
    path = find_existing_clone(urls) and return path
    url = urls.shift
    begin
      clone_repo!(url)
    rescue CloneError
      url = urls.shift and retry or raise
    end
  end
  
  def clone_path_for_url(url)
    File.expand_path(File.join(base_path, "repositories", pretty_path_for_url(url)))
  end
  
  def clone_repo!(url)
    clone_path = clone_path_for_url(url)
    FileUtils.mkdir_p(File.dirname(clone_path))
    clone!(url, clone_path, "--no-checkout") unless File.exists?(clone_path)
    clone_path
  end
  
  def checkout!(repo, commit, try_pull = true)
    _pwd = Dir.pwd
    
    cpath = File.expand_path(File.join(base_path, "checkouts", File.basename(repo), commit))
    FileUtils.mkdir_p(File.dirname(cpath))
    
    unless File.exists?(cpath)
      clone!(repo, cpath, "--shared")
      Dir.chdir(cpath)
      unless system("git checkout #{commit}")
        FileUtils.rm_rf(cpath)
        # pull bare repo, try to checkout again
        try_pull or raise(Error, "Git checkout #{repo} -> #{commit} failed!")
        $stderr.puts "Failed to checkout #{commit}: trying to fetch updates for #{repo}..."
        Dir.chdir(repo)
        system("git fetch") or raise(Error, "Git fetch inside #{repo} failed!")
        cpath = checkout!(repo, commit, false)
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
  
  def find_existing_clone(urls)
    urls.map{|u| clone_path_for_url(u) }.detect{|p| File.exists?(p)}
  end
  
  def pretty_path_for_url(url)
    url.gsub(%r{(\.git)?/*$},       "").
        gsub(%r{^(file:)?/+},       "blah:///localhost/").
        gsub(%r{^\w+:/+},           "").
        gsub(%r{[:/]},              "-")
  end
    
  def rewrite_rules
    @rewrite_rules ||= []
  end
  
  def filter_urls(rules, urls)
    rules.inject(urls) do |list, rule|
      list.inject([]) do |tail, url| 
        tail + [rule.call(url)].flatten.compact
      end
    end.uniq
  end
  
  class RewriteRule < Struct.new(:regexp, :block)
    def call(url) # maps 1 url to 0..n urls (may return string or nil)
      match = url.match(regexp)
      match ? block.call(url, *match.captures) : url
    end
  end
  
  class Error < StandardError; end
  class CloneError < Error; end
end
