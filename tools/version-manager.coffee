path = require 'path'
{promisify} = require 'util'
branchName = promisify(require 'git-branch-name')
updateJson = require 'update-json-file'

inc = (n) -> "#{parserInt(n) + 1}"

log = (previous, next) ->
  if next is previous
    console.log 'Current version unchanged:', previous
  else
    console.log 'Replace', previous, 'with', next

InvalidSituationError = (version, name) ->
  new Error "Invalid situation: you should not have a version #{version} on branch #{name}"

module.exports =
  create: (rootPath) ->
    pkgPath = path.resolve rootPath, 'package.json'
    try
      name = await branchName rootPath
      console.log 'Current branch:', name
      unless name? then throw new Error 'No branch found'
      [type, subName] = name.split '/'
      switch type
        when 'hotfix'
          await updateJson pkgPath, (pkg) ->
            {version} = pkg
            [mainVersion, subVersion] = version.split '-'
            next = "hotfix.#{subName?.replace /-/g, ''}.0"
            pkg.version = "#{mainVersion}-#{next}" unless subVersion?
            log version, pkg.version
            pkg
        when 'release'
          await updateJson pkgPath, (pkg) ->
            {version} = pkg
            [mainVersion, subVersion] = version.split '-'
            [subType] = subVersion.split '.'
            pkg.version = "#{mainVersion}-rc.0" if subType is 'beta'
            log version, pkg.version
            pkg
        when 'feature'
          await updateJson pkgPath, (pkg) ->
            {version} = pkg
            [mainVersion, subVersion] = version.split '-'
            [subType] = subVersion.split '.'
            next = "feature.#{subName?.replace /-/g, ''}.0"
            pkg.version = "#{mainVersion}-#{next}" if subType is 'beta'
            log version, pkg.version
            pkg
        else
          console.log 'Nothing to update'
    catch error
      console.error 'Error:', error
  update: (rootPath) ->
    pkgPath = path.resolve rootPath, 'package.json'
    hstPath = path.resolve rootPath, 'tools/version-history.json'
    latest = ''
    try
      name = await branchName rootPath
      console.log 'Current branch:', name
      unless name? then throw new Error 'No branch found'
      [type, subName] = name.split '/'
      switch type
        when 'master'
          await updateJson pkgPath, (pkg) ->
            await updateJson hstPath, (hst) ->
              {version} = pkg
              {master} = hst
              [_, subVersion] = version.split '-'
              unless subVersion? then throw new Error 'You are not allowed to update version on master'
              [subType, sutbPatch] = subVersion.split '.'
              switch subType
                when 'rc'
                  [mainVersion] = version.split '-'
                  [major, minor] = mainVersion.split '.'
                  latest = hst.master = pkg.version = "#{major}.#{minor}.#{subPatch}"
                  log master, pkg.version
                when 'hotfix'
                  [major, minor, patch] = master.split '.'
                  latest = hst.master = pkg.version = "#{major}.#{minor}.#{inc patch}"
                  log master, pkg.version
                else
                  throw InvalidSituationError version, name
              hst
            pkg
          latest
        when 'hotfix'
          await updateJson pkgPath, (pkg) ->
            {version} = pkg
            [mainVersion, subVersion] = version.split '-'
            latest = pkg.version unless subVersion?
            unless latest is ''
              log version, pkg.version
              return pkg
            [subType] = subVersion.split '.'
            switch subType
              when 'hotfix'
                [rest..., patch] = version.split '.'
                latest = pkg.version = [rest..., inc patch].join '.'
                log version, pkg.version
              else
                throw InvalidSituationError version, name
            pkg
          latest
        when 'release'
          await updateJson pkgPath, (pkg) ->
            {version} = pkg
            [mainVersion, subVersion] = version.split '-'
            [subType] = subVersion.split '.'
            switch subType
              when 'beta'
                latest = pkg.version = "#{mainVersion}-rc.0"
                log version, pkg.version
              when 'rc'
                [rest..., patch] = version.split '.'
                latest = pkg.version = [rest..., inc patch].join '.'
                log version, pkg.version
              else
                throw InvalidSituationError version, name
            pkg
          latest
        when 'dev'
          await updateJson pkgPath, (pkg) ->
            await updateJson hstPath, (hst) ->
              {version} = pkg
              {dev} = hst
              [mainVersion, subVersion] = version.split '-'
              [subType] = subVersion.split '.'
              switch subType
                when 'beta'
                  [_, subPatch] = subVersion.split '.'
                  latest = hst.dev = pkg.version = "#{mainVersion}-beta.#{inc subPatch}"
                  log version, pkg.version
                when 'rc'
                  [mainVersion] = dev.split '-'
                  [major, minor] = mainVersion.split '.'
                  [_, subPatch] = subVersion.split '.'
                  latest = hst.dev = pkg.version = "#{major}.#{minor}.#{subPatch}-beta.0"
                  log dev, pkg.version
                when 'hotfix'
                  [major, minor, patch] = mainVersion.split '.'
                  latest = hst.dev = pkg.version = "#{major}.#{minor}.#{inc patch}-beta.0"
                  log dev, pkg.version
                when 'feature'
                  [mainVersion] = dev.split '-'
                  [major, minor] = mainVersion.split '.'
                  latest = hst.dev = pkg.version = "#{major}.#{inc minor}.0-beta.0"
                  log dev, pkg.version
                else
                  throw InvalidSituationError version, name
              hst
            pkg
          latest
        when 'feature'
          await updateJson pkgPath, (pkg) ->
            {version} = pkg
            [mainVersion, subVersion] = version.split '-'
            [subType] = subVersion.split '.'
            switch subType
              when 'beta'
                next = "feature.#{subName?.replace /-/g, ''}.0"
                latest = pkg.version = "#{mainVersion}-#{next}"
                log version, pkg.version
              when 'feature'
                [_, featureName, subPatch] = subVersion.split '.'
                latest = pkg.version = "#{mainVersion}-feature.#{featureName}.#{inc subPatch}"
                log version, pkg.version
              else
                throw InvalidSituationError version, name
            pkg
          latest
        else
          throw new Error 'Type of branch not recognized'
    catch error
      console.error 'Error:', error
      throw error

