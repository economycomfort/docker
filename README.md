# docker-media
Files relating to docker services for home media streaming.

## Secrets
Files within the `secrets` directory are GPG encrypted upon commit with `git-crypt`.
After cloning, use `git-crypt unlock` and enter the GPG key passphrase to decrypt.

To decrypt, make sure you've added a GPG key with `git-crypt add-gpg-user <GPG_KEY_ID>`.

More info [here](https://www.guyrking.com/2018/09/22/encrypt-files-with-git-crypt.html).

See `.gitattributes` for files here which are encrypted.  If it's not listed there,
it's fine.

## Appdata symlink
For convenience, a symlink should point to where container service configuration files live:

`source ~/.env && ln -s $APPDATA appdata`

Or run the somewhat-unnecessary `./set_symlink.sh` script.
