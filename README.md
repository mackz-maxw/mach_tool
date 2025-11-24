# 自写小工具分享

### robust_top_ips.sh

- 一个用于从 web access.log 中统计指定日期（默认今天）响应码为 200 的 IP 出现次数，并列出前 N 个 IP 的小脚本  
- 适合 Nginx/Apache 的 common/combined 日志格式。脚本用 awk 单进程统计，然后 sort/head 输出 Top N

快速使用
- 赋可执行权限（从网络或其他主机下载后需要执行）：
  chmod +x robust_top_ips.sh
- 运行（默认 topN=5，默认日期为今天）：
  ./robust_top_ips.sh -f access.log
- 指定 topN 和日期（日期格式 `DD/Mon/YYYY`，例如 `10/Oct/2000`）：
  ./robust_top_ips.sh -f access.log -n 10 -d 10/Oct/2000

支持环境与依赖
- 需要：bash、awk、sort、head、mktemp  

示例日志格式（脚本假定 `$4` 为 `[DD/Mon/YYYY:...`，`$9` 为状态码）  
- CLF(Combined Log Format) 示例行：
  127.0.0.1 - - [10/Oct/2000:13:55:36 -0700] "GET /index.html HTTP/1.0" 200 2326 "http://ref" "Mozilla/5.0"

注意事项与常见问题
- chmod：从网络下载脚本后，需用 `chmod +x` 赋予可执行权限  
- **！！注意！！**`set -euo pipefail` 的（可能）副作用：  
  - `-e` 会在任一命令返回非零码时退出；`-o pipefail` 会使管道中任一子命令失败导致整体失败。  
  - 某些命令在“未匹配到结果”时会返回 1（例如 `grep` 无匹配），若脚本期望这种情况并继续运行，需要显式处理。  
  - 解决办法：对可能返回 1 的命令使用 `|| true` 或先检测再处理；或者在特定行使用 `set +e`/`set -e` 临时关闭；更稳健的方法是用 awk 的计数逻辑（awk 本身不会因无匹配而退出非零）。  
- 日志格式不一：若你的 access.log 字段与假定不同（例如时间或状态码位置不在 $4/$9），需要先用合适的 FS（-F）或预处理（sed）调整字段。  
- 权限/安全：请勿把敏感信息（如凭证）放入命令行参数或公开日志样本。临时文件使用 `mktemp`，并在 `trap` 中清理以避免残留。

运行例子（本仓库示例）
- 查看示例日志文件的前5条：
  ./robust_top_ips.sh -f sample_access.log
