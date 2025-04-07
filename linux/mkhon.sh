#!/bin/bash
# 创建漫画 zip/cbz 包

# 默认参数使用环境变量
DEFAULT_SOURCE=$MKHON_SOURCE
DEFAULT_TARGET=$MKHON_TARGET
INCLUDE_EXTENSIONS=(bmp jpg png gif webp avif apng)

# 处理参数
ARGS=$(getopt --option dhi:o:y --long delete,help,input:,output:,yes -- "$@")
eval set -- "${ARGS}"
shouldDelete=false
shouldShowHelp=false
isConfirmed=false
sourceDir=$DEFAULT_SOURCE
targetDir=$DEFAULT_TARGET
while true; do
  case "$1" in
  -d | --delete)
    shouldDelete=true
    shift
    ;;
  -h | --help)
    shouldShowHelp=true
    shift
    ;;
  -i | --input)
    sourceDir=$2
    shift 2
    ;;
  -o | --output)
    targetDir=$2
    shift 2
    ;;
  -y | --yes)
    isConfirmed=true
    shift
    ;;
  --)
    shift
    break
    ;;
  esac
done

# 显示帮助
if $shouldShowHelp; then
  echo "用法: mkhon [选项]"
  echo "选项:"
  echo "  -d, --delete        完成后删除已转换的文件夹"
  echo "  -h, --help          显示帮助"
  echo "  -i, --input <path>  输入目录"
  echo "  -o, --output <path> 输出目录"
  echo "  -y, --yes           确认操作"
  exit 0
fi

# 去除路径结尾的 '/'
sourceDir=${sourceDir%/}
targetDir=${targetDir%/}

# find 筛选
findInclude=''
for ext in "${INCLUDE_EXTENSIONS[@]}"; do
  findInclude="${findInclude} -o -iname '*.${ext}'"
done
findInclude=${findInclude# -o }

# 输入输出文件夹不存在则退出
if [ ! -d "$sourceDir" ]; then
  echo -e "源目录不存在: \e[33m$sourceDir\e[0m"
  exit 126
fi
if [ ! -d "$targetDir" ]; then
  echo -e "目标目录不存在: \e[33m$targetDir\e[0m"
  exit 126
fi

# 显示即将处理的信息
echo -e "源: \e[36m${sourceDir}\e[0m"
echo -e "目标: \e[36m${targetDir}\e[0m"

mapfile -t folders < <(find "$sourceDir" -mindepth 1 -maxdepth 1 -type d | awk -F/ '{print $NF}')
for d in "${folders[@]}"; do
  echo -e "包: \e[36m${d}\e[0m"
done

# 等待确认
if ! $isConfirmed; then
  read -r -p "创建并删除源文件? Yes/no: " confirm
  if [[ ! "${confirm,,}" =~ ^y|yes$ ]]; then
    exit 0
  fi
fi

# 按日期创建子文件夹
targetDir="${targetDir}/$(date "+%Y%m%d")"
if [ ! -d "$targetDir" ]; then
  mkdir "$targetDir"
fi
if [ -f "$targetDir" ]; then
  echo -e "目标为文件: \e[32m${targetDir}\e[0m"
  exit 126
fi

# 对于每个文件夹
for d in "${folders[@]}"; do
  # 获取每个文件夹中的文件的数组
  mapfile -t filelist < <(eval "find \"\${sourceDir}/\${d}\" -type f ${findInclude}")
  if [ ${#filelist[@]} -eq 0 ]; then
    echo -e "\e[31m${d}.zip\e[0m 未找到合法文件"
    continue
  fi
  # 开始创建
  echo -e "创建 \e[36m${d}.zip\e[0m ..."
  7z a -mx0 "${targetDir}/${d}.zip" "${filelist[@]}"
  # 删除该文件夹
  if $shouldDelete && ! $?; then
    rm -r "${sourceDir:?}/${d}"
  fi
done
echo -e "处理完成，共 \e[32m${#folders[@]}\e[0m 个"
