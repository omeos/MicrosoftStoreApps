# Git Large File Storage - git-lfs.com
# Git LFS per file size <= 2G
# Git files per file size <= 100M
# Git releases per file size <= 2G
(
   set -e -x
   # 当不是一个裸仓库
   test "$(git rev-parse --is-bare-repository)" != false || {
      # 切换至仓库根目录
      cd -L -- "$(git rev-parse --show-toplevel || dirname -- "${0}")"
      # 强制配置仓库钩子
      _="$(git-lfs install --force --local)"
      # 清理旧的跟踪规则
      test ! -f .gitattributes || sed -i -e '/=lfs[[:space:]]/d' -- .gitattributes
      # 查找指定文件大小 > 100M (104857600B)
      find . -mindepth 1 ! -type d -size +100M -exec sh -c '
         for i in "${@}"; do
            i="${i#./}" && {
               # 确保在仓库工作树
               _="$(cd -L -- "$(dirname -- "${i}")" && test "$(git rev-parse --is-inside-work-tree)" != false)" || continue
               # 重新更新跟踪规则
               git-lfs track --filename "${i}"
            }
         done
      ' - "{}" +
      # 确保强制跟踪 .gitattributes 文件
      test ! -f .gitattributes || {
         git add --verbose --force .gitattributes
         # 尝试创建初始提交
         _="$(git log -1 2>&1)" || git commit --verbose --all --no-edit --no-allow-empty --allow-empty-message || true
      }
      git-lfs track
      git-lfs status
      git-lfs ls-files --long --size
      # 如果存在提交记录
      _="$(! git log -1 2>&1)" || {
         # 拉取远程所有 LFS 文件
         : git-lfs pull origin
         # 推送本地所有 LFS 文件
         git-lfs push --all origin
      }
   }
)
# (set -x; sh -- git_lfs_track.sh && git add --verbose --all && git commit --verbose --all --no-edit --no-allow-empty --allow-empty-message && (_="$(! git log -1 2>&1)" || : git pull --verbose --rebase origin) && git push --verbose --all --follow-tags $(: --force-with-lease) origin)