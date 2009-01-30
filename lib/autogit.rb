require 'fileutils'

module Kernel
  def autogit(*args,&blk)
    AutoGit.require_git_repo(*args,&blk)
  end
end

module AutoGit extend self
  
  def require_git_repo(urls, commit)
    urls = filter_urls(rewrite_rules, [urls].flatten)
    return if urls.empty?
    set_load_path!(
      checkout!(
        clone_one_of_repos!(urls), 
          commit)
            )
  end
  
  attr_accessor :base_path
  def base_path
    @base_path || ENV['AUTOGIT_BASE_PATH'] || "~/.autogit"
  end
  
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
  
  def rewrite(regexp, value = nil, &blk)
    rewrite_rules.unshift(RewriteRule.new(regexp, blk || proc{|*_| value }))
  end
  
  def filter_urls(rules, urls)
    rules.inject(urls) do |list, rule|
      list.inject([]) do |tail, url| 
        tail + [rule.call(url)].flatten.compact
      end
    end
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
