# Update

Step 1: 检查 `file` 目录  

**提示**：`groups.lua` 和 `increment.tar.gz` 不能共存，`file` 目录中只能存在其中一个。

Step 2: 检查 `increment.tar.gz` 解压产物  

**要求**：  

- 确认 `increment.tar.gz` 解压后能生成一个 `app` 目录。  

- **压缩方式**：  

  ```shell
  mkdir app && find . -maxdepth 1 -not -name "app" -not -name "." -exec cp -r {} app/ \; && tar -zcvf increment.tar.gz app
  ```

Step 3: 检查 `hosts` 文件中各个服务的 `ip` 是否正确  

Step 4: 启动  

**提示**：  

```shell
bash start.sh
```

💡 单独执行剧本    

```shell
# 更新groups
# cross
ansible-playbook playbook/cross/cross-entry.yaml -t groups
# game
ansible-playbook playbook/game/game-entry.yaml -t groups

# 其他类型更新
# cross
ansible-playbook playbook/cross/cross-entry.yaml -t increment
# game
ansible-playbook playbook/game/game-entry.yaml -t increment
# gm
ansible-playbook playbook/gm/gm-entry.yaml
# log
ansible-playbook playbook/log/log-entry.yaml
```