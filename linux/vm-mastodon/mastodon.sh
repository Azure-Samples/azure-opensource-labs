cd $HOME

export SITE_ADDRESS=$(jq -r '.siteAddress' env.json)
export LETS_ENCRYPT_EMAIL=$(jq -r '.letsEncryptEmail' env.json)
export TLS_INTERNAL=''

git clone https://github.com/asw101/tmp -b fractured-monkey-1
cd tmp

make all
