#!/usr/bin/env io

AutoGit := Object clone do(
  requireGitRepo := method(urls, commit,
    setLoadPath(
      checkout(
        cloneOneOfRepos(list(urls) flatten), 
          commit)
            )
  )
  
  cloneOneOfRepos := method(urls,
    //
    ""
  )
  
  clonePathForURL := method(url, 
    //System getEnvironmentVariable("HOME")
  )
  
  
  
)

autogit := AutoGit getSlot("requireGitRepo")
