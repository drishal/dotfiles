 repo_remote="$(git remote get-url "${1:-origin}" || exit 1)"
  
  case $repo_remote in
      git@github*)
          repo=${repo_remote##git@github.com:}
          repo=${repo%%.git}
          repo=https://github.com/$repo
      ;;  
  
      *https*github*)
          repo=${repo_remote##https://github.com/}
          repo=${repo%%.git}
          repo=git@github.com:$repo.git
      ;;  
  
      *) exit 1 ;;
  esac
  
  printf 'Changing repo to %s\n' "$repo"
  git remote set-url origin "$repo"