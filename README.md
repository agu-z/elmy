# elmy

Write native apps with elm. Very experimental.

## Contributing

This project uses git hooks. Make sure to set them up before commiting:

First check your git version:

```console
$ git --version
```

If your git version is >= 2.9 do:

```console
$ git config core.hooksPath .githooks
```

otherwise do:

```console
$ find .git/hooks -type l -exec rm {} \; && find .githooks -type f -exec ln -sf ../../{} .git/hooks/ \;
```

