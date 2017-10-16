# Automatic package versioning example

## Description

Proof of concept to implement a git-flow-like workflow for automatically incrementing npm package version following the current git branch

## Rules

| Branch        | Pattern                                                       | Example                |
|---------------|:--------------------------------------------------------------|:-----------------------|
|`master`       |**major**.**minor**.**patch**                                  |_(1.1.0)_               |
|`hotfix/x-x-x` |**major**.**minor**.**patch**-**hotfix**.**name**.**subpatch** |_(1.1.0-hotfix.xxx.0)_  |
|`release/1.2.0`|**major**.**minor**.**patch**-**rc**.**subpatch**              |_(1.2.0-rc.0)_          |
|`dev`          |**major**.**minor**.**patch**-**beta**.**subpatch**            |_(1.3.0-beta.0)_        |
|`feature/f-f-f`|**major**.**minor**.**patch**-**feature**.**name**.**subpatch**|_(1.3.0-feature.fff.0)_ |
