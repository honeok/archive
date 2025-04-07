# Update

## Update steps

> Step 1: Preparation

⚠️ **Requirement:** Ensure that extracting `increment.tar.gz` or `updategame.tar.gz`  generates an `app` directory.

✨ The first run of `./update.sh` will generate the shared path `$PWD/share` file, which serves as a prerequisite for playbook execution.

> Step 2: Create Incremental Update Package

Maintainable incremental updates for the server.

```shell
tar -zcf increment.tar.gz app/
```

> Step 3: Create Full Update Package

Package the app for a server-stop update.

```shell
tar -zcf updategame.tar.gz app/
```

> Step 4: Execute Update

🕹️ Finally, run the update script.

```shell
./update.sh
```

## References

- [https://hellogitlab.com/CM/ansible/changed_when](https://hellogitlab.com/CM/ansible/changed_when) - changed_when与failed_when条件判断