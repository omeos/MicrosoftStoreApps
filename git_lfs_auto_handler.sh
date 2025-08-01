# Git Large File Storage - git-lfs.com
# Git LFS per file size <= 2G
# Git files per file size <= 100M
# Git releases per file size <= 2G
# 请务必在每次 git add 之前执行脚本
# 脚本执行示例
# (set -x; sh git_lfs_auto_handler.sh && git add --verbose --all && git commit --verbose --all --no-edit --no-allow-empty --allow-empty-message && (_="$(! git log -1 2>&1)" || : git pull --verbose --rebase origin) && git push --verbose --all --follow-tags $(: --force-with-lease) origin || exit "${?}")
(
   # 100M (104857600c) < LFS <= 2G (2147483648c), SPLIT = 2G (2147483648)
   LFS_MIN_SIZE=+100M && LFS_MAX_SIZE=+2G && SPLIT_FILE_SIZE=2G
   eval "ECHO$(printf %s KCkgeyBjYXQgPDwtRU5ECiR7Kn0KRU5ECn0= | base64 -d)" || exit "${?}"
   # 当不是一个裸仓库
   test "$(git rev-parse --is-bare-repository)" != false || {
      # 注册命令别名 git lfs.auto 与 git lfs-auto
      for i in alias.lfs.auto alias.lfs-auto; do
         git config unset --local --all -- "${i}" || true
         # 命令别名工作目录总是在仓库根目录，全局变量 GIT_PREFIX 指向实际目录
         git config set --local --all -- "${i}" '!main() { (sh git_lfs_auto_handler.sh "${@}"); } && main "${@}"; exit "${?}"; #' || continue
      done || true
      # 切换至仓库根目录
      cd -L -- "$(git rev-parse --show-toplevel)" || exit "${?}"
      ECHO "工作目录 $(pwd -L)" 1>&2
      # 建立忽略规则文件
      excludesFile="${HOME}/.git/info/$(basename -- "$(pwd -L)")/exclude" || exit "${?}"
      mkdir -p -- "$(dirname -- "${excludesFile}")" || exit "${?}"
      # 查找指定文件大小 > 2G (2147483648c)
      find . -mindepth 1 ! -type d ! "(" "(" -type d -a -path "*/.git" ")" -o -path "*/.git/*" ")" -size "${LFS_MAX_SIZE}" -exec sh -c '
         SPLIT_FILE_SIZE="${0}"
         eval "ECHO$(printf %s KCkgeyBjYXQgPDwtRU5ECiR7Kn0KRU5ECn0= | base64 -d)" || exit "${?}"
         for i in "${@}"; do
            i="${i#./}" && (
               # 切换当前工作目录
               cd -L -- "$(dirname -- "${i}")" || exit "${?}"
               ECHO "[大文件分割] 工作目录 $(pwd -L)" 1>&2
               # 确保在仓库工作树
               test "$(git rev-parse --is-inside-work-tree)" != false || exit "${?}"
               # 当前文件名称
               fn="$(basename -- "${i}")" || exit "${?}"
               # 临时文件前缀
               tmp=".split_$(printf %s "${i}" | md5sum | cut -c -32)." || exit "${?}"
               # 历史分割文件
               find . -mindepth 1 -maxdepth 1 ! -type d "(" -name "$(
                  # 必要名称转义
                  printf %s "${fn}" | sed -e "$(
                     ### s/\[/\\&/g;s/\]/\\&/g;s/\*/\\&/g
                     printf %s cy9cWy9cXCYvZztzL1xdL1xcJi9nO3MvXCovXFwmL2c= | base64 -d
                  )"
               ).*" -o -name "${tmp}*" ")" -exec sh -c "$(
                  cat <<-"END"
                  eval "ECHO$(printf %s KCkgeyBjYXQgPDwtRU5ECiR7Kn0KRU5ECn0= | base64 -d)" || exit "${?}"
                  for i in "${@}"; do
                     # 匹配分割文件
                     i="${i#./}" && {
                        printf %s "${i}" | grep -q -e "$(
                           ### \.[0-9][0-9]*$
                           printf %s XC5bMC05XVswLTldKiQ= | base64 -d
                        )" -e "^${tmp}.*" || continue
                        ECHO "[大文件分割] 清理文件 ${i}" 1>&2
                        rm -f -- "${i}" || continue
                     }
                  done || true
END
               )" - "$(printf %s e30= | base64 -d)" + || true
               ECHO "[大文件分割] 分割文件 ${fn}" 1>&2
               # 分割指定文件 = 2G (2147483648)
               split -a 3 -b "${SPLIT_FILE_SIZE}" -- "${fn}" "${tmp}" || {
                  # 尝试清理文件
                  e="${?}" && find . -mindepth 1 -maxdepth 1 ! -type d -name "${tmp}*" -delete || true
                  exit "${e}"
               }
               # 当前分割文件
               find . -mindepth 1 -maxdepth 1 ! -type d -name "${tmp}*" -exec sh -c "$(
                  cat <<-"END"
                  eval "ECHO$(printf %s KCkgeyBjYXQgPDwtRU5ECiR7Kn0KRU5ECn0= | base64 -d)" || exit "${?}"
                  # 前导填充宽度
                  pad="0$(printf %s "${#}" | grep -o -e . | grep -c -e .)" || exit "${?}"
                  n= && for i in "${@}"; do
                    # 自增文件计数
                    i="${i#./}" && {
                       n="$(expr "${n:-0}" + 1)" && N="$(printf "%${pad}d" "${n}")" && fn="${0}.${N}" || continue
                       ECHO "[大文件分割] 生成文件 ${i} => ${fn}" 1>&2
                       # 更新文件名称
                       mv -f -T -- "${i}" "${fn}" || {
                          # 尝试清理文件
                          rm -f -- "${i}" || true
                          continue
                       }
                       # 引用文件时间
                       touch -c -r "${0}" -- "${fn}" || continue
                    }
                  done || true
END
               )" "${fn}" "$(printf %s e30= | base64 -d)" + || exit "${?}"
            ) && {
               # 是否已被跟踪
               if _="$(git ls-files --cached --error-unmatch -- "${i}" 2>&1)"; then
                  ECHO "[大文件分割] 停止跟踪文件 ${i}" 1>&2
                  # 移除跟踪缓存
                  git rm --force --cached -r -- "${i}" || continue
               fi
               ECHO "[大文件分割] 设置忽略文件 ${i} => .gitignore:.git/info/exclude" 1>&2
               # 忽略处理文件
               ECHO "${i}"
            }
         done || true
      ' "${SPLIT_FILE_SIZE}" "$(printf %s e30= | base64 -d)" + | sed -e 's/[^a-zA-Z0-9]/\\&/g' 1>"${excludesFile}" || exit "${?}"
      # 配置忽略规则文件
      git config set --local --all --path -- core.excludesFile "${excludesFile}" || exit "${?}"
      find . -mindepth 1 ! "(" "(" -type d -a -path "*/.git" ")" -o -path "*/.git/*" ")" -exec sh -c '
         eval "ECHO$(printf %s KCkgeyBjYXQgPDwtRU5ECiR7Kn0KRU5ECn0= | base64 -d)" || exit "${?}"
         first= && for i in "${@}"; do
            i="${i#./}" && {
               test -n "${first}" || {
                  _="$(git check-ignore --verbose -- "${i}")" && {
                     first=n && ECHO "[大文件分割] 当前忽略规则：" 1>&2
                  } || true
               }
               git check-ignore --verbose -- "${i}" || continue
            }
         done || true
      ' - "$(printf %s e30= | base64 -d)" + || true
      # 强制配置仓库钩子
      _="$(git-lfs install --force --local)" || exit "${?}"
      # 清理旧的跟踪规则
      test ! -f .gitattributes || {
         ECHO "[大文件存储] 清理规则 .gitattributes" 1>&2
         sed -i -e '/=lfs[[:space:]]/d' .gitattributes || true
      }
      # 查找指定文件大小 > 100M (104857600c) <= 2G (2147483648c)
      find . -mindepth 1 ! -type d ! "(" "(" -type d -a -path "*/.git" ")" -o -path "*/.git/*" ")" "(" -size "${LFS_MIN_SIZE}" -a ! -size "${LFS_MAX_SIZE}" ")" -exec sh -c '
         eval "ECHO$(printf %s KCkgeyBjYXQgPDwtRU5ECiR7Kn0KRU5ECn0= | base64 -d)" || exit "${?}"
         for i in "${@}"; do
            i="${i#./}" && {
               (
                  # 切换当前工作目录
                  cd -L -- "$(dirname -- "${i}")" || exit "${?}"
                  ECHO "[大文件存储] 工作目录 $(pwd -L)" 1>&2
                  # 确保在仓库工作树
                  test "$(git rev-parse --is-inside-work-tree)" != false || exit "${?}"
               ) || continue
               ECHO "[大文件存储] 更新规则 ${i} => .gitattributes" 1>&2
               # 重新更新跟踪规则
               git-lfs track --filename -- "${i}" || continue
            }
         done || true
      ' - "$(printf %s e30= | base64 -d)" + || exit "${?}"
      # 确保强制跟踪 .gitattributes 文件
      test ! -f .gitattributes || {
         ECHO "[大文件存储] 跟踪文件 .gitattributes" 1>&2
         git add --verbose --force .gitattributes || exit "${?}"
         # 尝试创建初始提交
         _="$(git log -1 2>&1)" || {
            ECHO "[大文件存储] 创建初始提交：" 1>&2
            git commit --verbose --all --no-edit --no-allow-empty --allow-empty-message || exit "${?}"
         }
      }
      ECHO "[大文件存储] 当前跟踪规则：" 1>&2
      git-lfs track || true
      if false; then
         ECHO "[大文件存储] 文件跟踪状态：" 1>&2
         # 并发执行耗时操作
         git-lfs status & pid="${!}"
         git-lfs ls-files --all --long --size & pid="${pid:+"${pid} "}${!}"
         # 等待后台任务完成
         eval wait "${pid}" || true
      fi
      (
         srcHooksPath="$(git rev-parse --git-dir)/hooks" || exit "${?}"
         mkdir -p -- "${srcHooksPath}" || exit "${?}"
         chmod -R -- 0755 "${srcHooksPath}" || exit "${?}"
         # 是否存在无权文件
         if _="$(find "${srcHooksPath}" -mindepth 1 ! -type d -exec test ! -x "$(printf %s e30= | base64 -d)" ";" -print | grep -e .)"; then
            dstHooksPath="${HOME}/.git/hooks/$(basename -- "$(pwd -L)")" || exit "${?}"
            ECHO "[大文件存储] 镜像钩子路径 ${srcHooksPath} => ${dstHooksPath}" 1>&2
            mkdir -p -- "${dstHooksPath}" || exit "${?}"
            # 尝试清理文件
            find "${dstHooksPath}" -mindepth 1 ! -type d -delete || true
            cp -f -a -T -- "${srcHooksPath}" "${dstHooksPath}" || exit "${?}"
            chmod -R -- 0755 "${dstHooksPath}" || exit "${?}"
            # 配置仓库钩子路径
            git config set --local --all --path -- core.hooksPath "${dstHooksPath}" || exit "${?}"
         fi
      ) || {
         # 移除仓库钩子路径
         git config unset --local --all core.hooksPath || exit "${?}"
         # 如果存在提交记录
         _="$(! git log -1 2>&1)" || {
            ECHO "[大文件存储] 手动执行推送：" 1>&2
            git add --verbose --all || exit "${?}"
            # 拉取远程所有 LFS 文件
            : git-lfs pull origin || exit "${?}"
            # 推送本地所有 LFS 文件
            git-lfs push --all origin || exit "${?}"
         }
      }
   } || exit "${?}"
   if false; then
      # 创建测试文件
      for i in 104857599c:-100M 104857600c:100M 104857601c:+100M 1342177280c:1280M; do
         _="$(dd if=/dev/zero of="${i#*:}" bs="${i%:*}" count=0 seek=1 status=none)" || continue
      done || true
   fi
) 2>&1