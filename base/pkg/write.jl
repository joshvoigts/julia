module Write

using Base.Git, ..Cache, ..Read

function prefetch(pkg::String, sha1::String)
    isempty(Cache.prefetch(pkg, Read.url(pkg), sha1)) && return
    error("$pkg: couldn't find commit $(sha1[1:10])")
end

function fetch(pkg::String, sha1::String)
    refspec = "+refs/heads/*:refs/remotes/cache/*"
    Git.run(`fetch -q $(Cache.path(pkg)) $refspec`, dir=pkg)
    Git.iscommit(sha1, dir=pkg) && return
    f = Git.iscommit(sha1, dir=Cache.path(pkg)) ? "fetch" : "prefetch"
    error("$pkg: $f failed to get commit $(sha1[1:10]), please file a bug")
end

function checkout(pkg::String, sha1::String)
    Git.set_remote_url(Read.url(pkg), dir=pkg)
    Git.run(`checkout -q $sha1`, dir=pkg)
end

function install(pkg::String, sha1::String)
    prefetch(pkg, sha1)
    if isdir(".trash/$pkg")
        run(`mv .trash/$pkg ./`)
    else
        Git.run(`clone -q $(Cache.path(pkg)) $pkg`)
    end
    fetch(pkg, sha1)
    checkout(pkg, sha1)
end

function update(pkg::String, sha1::String)
    prefetch(pkg, sha1)
    fetch(pkg, sha1)
    checkout(pkg, sha1)
end

function remove(pkg::String)
    isdir(".trash") || mkdir(".trash")
    # this shouldn't happen in the course of normal operation:
    ispath(".trash/$pkg") && run(`rm -rf .trash/$pkg`)
    run(`mv $pkg .trash/`)
end

end # module
